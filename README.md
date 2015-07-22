# GeStoreGePan
GePan fork modified to use GeStore

## Requirements
------------
* Perl 5.14.2
* BLAST
* GeStore (if you want to use GeStore)
* UniProtKB
* Sun/Open Grid Engine

## Usage
-------
1. Modify GePan/Config.pm to reflect local paths
2. Use GePan/db_scripts/processDat.pl to generate annotation database
3. Use GePan/scripts/startGePan.pl to generate scripts for Grid Engine
4. Run scripts
