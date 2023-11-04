ABoW 🏹
======================================================

ABoW stands for Awk Bag of Words.

Usage
------------------------------------------------------

### Process files

Process files to the standard output:

```bash
abow -p FILE [...]
```
```bash
abow --process FILE [...]
```

Process files to an output file:

```bash
abow -p -o OUTPUT FILE [...]
```
```bash
abow --process --output OUTPUT FILE [...]
```

Where:

*   `FILE`: is a plain text file.
*   `OUTPUT`: is a tab-separated value file.

### List files

List files:

```bash
abow -l
```
```bash
abow --list
```

List files of a collection:

```bash
abow -l -c COLLECTION
```
```bash
abow --list --collection COLLECTION
```

List files of a collection selecting some metadata fields:

```bash
abow -l -c COLLECTION -m "suid,collection,name,size,date"
```
```bash
abow --list --collection COLLECTION --meta "suid,collection,name,size,date"
```

### Show files

Show a `text.txt` file:

```bash
abow -s SHORT_ID
```
```bash
abow --show SHORT_ID
```

Show a `meta.txt` file:

```bash
abow -s -m SHORT_ID
```
```bash
abow --show --meta SHORT_ID
```

Show a `data.tsv` file:

```bash
abow -s -d SHORT_ID
```
```bash
abow --show --data SHORT_ID
```

### Search in files

Search in `text.txt` files using a regex:

```bash
abow -g REGEX
```
```bash
abow --grep REGEX
```

Search in `meta.txt` files using a regex:

```bash
abow -g -m REGEX
```
```bash
abow --grep --meta REGEX
```

Search in `data.tsv` files using a regex:

```bash
abow -g -d REGEX
```
```bash
abow --grep -data REGEX
```

### Import files

Import files:

```bash
abow -i FILE [...]
```
```bash
abow --import FILE [...]
```

Import files recursivelly:

```bash
abow -i -r DIRECTORY [...]
```
```bash
abow --import --recursive DIRECTORY [...]
```

Import files recursivelly into a collection:

```bash
abow -i -r -c COLLECTION DIRECTORY [...]
```
```bash
abow --import --recursive --collection COLLECTION DIRECTORY [...]
```

Where:

*   `FILE`: is a plain text file.
*   `DIRECTORY`: is a directory containing files with ".txt" suffix.
*   `COLLECTION`: is an arbitrary name for groups of imported files.

If no collection name is informed, the "default" collection is implied.

If a file exists, an error message is written to `/dev/stderr`.

You can force to import files again using the `--force` option.

The `data` directory
------------------------------------------------------

The imported files are stored in the `data` folder.

The imported files are grouped in sub-folders called "collections" under the `data` folder.

```bash
tree data
```
```
data
└── default
    ├── 25cc123e
    │   └── 25cc123e-66c5-35ac-8b32-bc8ef803abdf
    │       ├── data.tsv
    │       ├── meta.txt
    │       └── text.txt
    └── 80a7c9ab
        └── 80a7c9ab-8f0c-31ab-9f72-251367cf6557
            ├── data.tsv
            ├── meta.txt
            └── text.txt
```

Where:

*   `data.tsv`: is a tab-separated value file containing the bag of words.
*   `meta.txt`: is a key-value file containing some properties.
*   `text.txt`: is a copy of the input text file.

And where:

*   `default`: is the default collection name.
*   `25cc123e`: is a short ID to derived from the file's UUIDv8.
*   `25cc123e-66c5-35ac-8b32-bc8ef803abdf`: is a UUIDv8 derived from the file content.

The short ID is just an abbreviated form of the UUIDv8. It is not meant to be globally unique, not even in a collection scope.

The `data.tsv` file
------------------------------------------------------

The `data.tsv` file is a tab-separated value file containing a bag of words.

Fields:

*   `TOKEN`: is a word, a punctuation symbol or a `<EOL>` symbol.
*   `COUNT`: is the number of occurencies of the token in the text.
*   `RATIO`: is the COUNT divided by the number of all tokens in the text.
*   `CLASS`: is a POSIX character classes: 'A' for `[:alpha:]`, 'D' for `[:digit:]`, 'P' for `[:punct:]`, and 'NA' for none.
*   `CASE`: is one of these letter cases: 'L' for lowercase, 'U' for uppercase, 'C' for capitalized word, and 'NA' for none.
*   `LENGTH`: is the number of characters in the token.
*   `INDEXES`: is the comma-separated list of all positions of a token in the text.

Where:

*   `<EOL>`: is a symbol for the end of line.
*   'NA': is a missing value borrowed from R language.

If a token has only 1 character and this character is an uppercase letter, then this token is treated as a capitalized word.

Only line endings (\n) and tabs (\t) separate records and fields, respectively. No quotes are used, despite Github complaints about ["unclosed quoted fields"](https://docs.github.com/pt/repositories/working-with-files/using-files/working-with-non-code-files). If you are curiouse aboute TSV files, [read this](https://github.com/eBay/tsv-utils/blob/master/docs/comparing-tsv-and-csv.md).

This is an example of a bag of words generated by this program:

TOKEN|COUNT|RATIO|CLASS|CASE|LENGTH|INDEXES
-----|-----|-----|-----|----|------|-------
Doutrina|1|0.013698630|A|C|8|52
professor|1|0.013698630|A|L|9|33
Itália|1|0.013698630|A|C|6|8
consultor|1|0.013698630|A|L|9|40
Congregação|2|0.027397260|A|C|11|43,49
em|2|0.027397260|A|L|2|10,69
artigo|1|0.013698630|A|L|6|59
hoje|1|0.013698630|A|L|4|48
incorpora|1|0.013698630|A|L|9|60
texto|1|0.013698630|A|L|5|61
para|1|0.013698630|A|L|4|50
(|3|0.041095890|P|NA|1|3,12,47
Franciscanos|1|0.013698630|A|C|12|24
)|3|0.041095890|P|NA|1|14,15,55
XVIII|1|0.013698630|A|U|5|29
,|5|0.068493151|P|NA|1|5,7,20,25,65
.|3|0.041095890|P|NA|1|30,56,72
público|1|0.013698630|A|L|7|71
também|1|0.013698630|A|L|6|32
Ferraris|1|0.013698630|A|C|8|2
Encyclopedia|1|0.013698630|A|C|12|64
Ofício|1|0.013698630|A|C|6|46
?|1|0.013698630|P|NA|1|13
dos|1|0.013698630|A|L|3|23
da|6|0.082191781|A|L|2|21,36,41,42,53,62
de|1|0.013698630|A|L|2|67
Santo|1|0.013698630|A|C|5|45
sacerdote|1|0.013698630|A|L|9|18
Fé|1|0.013698630|A|C|2|54
canonista|1|0.013698630|A|L|9|26
Lucius|1|0.013698630|A|C|6|1
um|1|0.013698630|A|L|2|17
domínio|1|0.013698630|A|L|7|70
Alexandria|1|0.013698630|A|C|10|6
do|2|0.027397260|A|L|2|27,44
italiano|1|0.013698630|A|L|8|19
Solero|1|0.013698630|A|C|6|4
século|1|0.013698630|A|L|6|28
1913|1|0.013698630|D|NA|4|68
ordem|1|0.013698630|A|L|5|38
Provincial|1|0.013698630|A|C|10|35
a|1|0.013698630|A|L|1|51
Catholic|1|0.013698630|A|C|8|63
Este|1|0.013698630|A|C|4|58
e|2|0.027397260|A|L|1|34,39
Ordem|1|0.013698630|A|C|5|22
Foi|1|0.013698630|A|C|3|31
publicação|1|0.013698630|A|L|10|66
sua|1|0.013698630|A|L|3|37
&lt;EOL&gt;|2|0.027397260|NA|NA|5|57,73
1763|1|0.013698630|D|NA|4|11
foi|1|0.013698630|A|L|3|16
falecido|1|0.013698630|A|L|8|9

The text was extracted from a random [Wikipedia page](https://pt.wikipedia.org/wiki/Lucius_Ferraris) in Portuguese.

Note that letter case, punctuation, end of line, and stop words are preserved. The author wants to keep them as they are. But they can be easily transformed or removed if necessary.

License
------------------------------------------------------

This project is Open Source software released under the [MIT license](https://opensource.org/licenses/MIT).
