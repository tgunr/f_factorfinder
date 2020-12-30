FactorFinder
============

Spotlight importer for indexing Factor source files. Permits searching metadata for Factor words and files. Currently, indexes the following attributes:

```
public_factor_uses         USING:
public_factor_uses           USE:
public_factor_tuples       TUPLE:
public_factor_symbols     SYMBOL:
public_factor_definitions       :
public_factor_definitions      ::
public_factor_definitions      M:
public_factor_definitions     M::
```

Also will index the header of a file that has the format:

```
kMDItemDisplayName ! File: test.factor<br/>
kMDItemCopyright   ! Copyright (C) 2011 PolyMicro Systems<br/>
                   ! See http://factorcode.org/license.txt for BSD license.<br/>
kMDItemVersion     ! Version: 1.0<br/>
kMDItemAuthors     ! DRI: Dave Carlton<br>
kMDItemDescription ! Description: Defintions for testing Factor spotlight<br/>
```

https://dsc.cloud/8e6a8d/1609337198.gif