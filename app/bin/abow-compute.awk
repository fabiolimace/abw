#!/usr/bin/gawk -f

# Notes:
#   * Files encoded using MAC-UTF-8 must be normalized to UTF-8.
#   * Non-breakin spaces (NBSP, 0xA0) must be converted to regular spaces.

function kind(token)
{
    switch (token) {
    case /^[[:alpha:]-]+$/:
        return "A"; # Alpha (with hyphen)
    case /^[[:digit:]]+$/:
        return "D"; # Digit (only)
    case /^[[:punct:]]+$/:
        return "P"; # Punct (only)
    default:
        return "NA";
    }
    
    # NOTE:
    # This function returns NA to words that contain "accented" characters encoded
    # with MAC-UTF-8. You must normilize the input files to regular UTF-8 encoding.
}

function style(token)
{
    switch (token) {
    case /^[[:lower:]]+(-([[:lower:]]+|[[:upper:]]+|[[:alpha:]][[:lower:]]+))*$/:
        return "L"; # Lower case: "word", "compound-word", "compound-WORD" and "compound-Word"
    case /^[[:upper:]][[:lower:]]*(-([[:lower:]]+|[[:upper:]]+|[[:alpha:]][[:lower:]]+))*$/:
        return "C"; # Capitalized: "Word", "Compound-word", "Compound-WORD" and "Compound-Word"
    case /^[[:upper:]]+(-([[:lower:]]+|[[:upper:]]+|[[:alpha:]][[:lower:]]+))*$/:
        return "U"; # Upper case: "WORD", "COMPOUND-word", "COMPOUND-WORD" and "COMPOUND-Word"
    default:
        return "NA";
    }
    
    # NOTE:
    # UPPERCASE words with a single character, for example "É", are treated as Capitalized words by this function.
    # The author considers it a very convenient behavior that helps to identify proper nouns and the beginning of 
    # sentences, although he admits that it may not be intuitive. The order of the switch cases is important to
    # preserve this behavior.
}

function join(array,    i, result)
{
    for (i in array) {
        if (i == 1) result = array[i];
        else result = result "," array[i];
    }
    return result
}

function insert(token) {
    total++;
    counters[token]++;
    indexes[token][counters[token]]=total;
}

BEGIN {

}

{
    for (i = 1; i <= NF; i++) {

        match($i, /^([[:punct:]]+)?\<(.+)\>([[:punct:]]+)?$/, matches);
        
        # puncts before
        if (matches[1]) {
            token=matches[1];
            if (length(token) > 1) {
                split(token, puncts, //);
                for (p in puncts) {
                    insert(puncts[p]);
                }
            } else {
                insert(token);
            }
        }
        
        if (matches[2]) {
            insert(matches[2]);
        }
        
        # puncts after
        if (matches[3]) {
            token=matches[3];
            if (length(token) > 1) {
                split(token, puncts, //);
                for (p in puncts) {
                    insert(puncts[p]);
                }                
            } else {
                insert(token);
            }
        }
    }
    
    insert("<EOL>")
    
    # NOTE:
    # Non-breaking Spaces (NBSP, 0xA0) cause wrong word slitting.
    # You must replace them with regular spaces.
}

END {

    # start of operational checks #
    for (k in counters) {
        sum += counters[k];
    }    
    if (sum != total) {
        print "Wrong sum of counts" > "/dev/stderr";
        exit 1;
    }
    # end of operational checks #

    print "TOKEN\tCOUNT\tRATIO\tKIND\tSTYLE\tLENGH\tINDEXES"
    
    for (token in counters) {
        count = counters[token];
        ratio = counters[token] / total;
        printf "%s\t%d\t%.9f\t%s\t%s\t%d\t%s\n", token, count, ratio, kind(token), style(token), length(token), join(indexes[token]);
    }
}

