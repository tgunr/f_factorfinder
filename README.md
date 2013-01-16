FactorFinder
============

Spotlight importer for indexing Factor source files. Permits searching metadata for Factor words and files. Currently, indexes the following attributes:

<pre>
public_factor_uses     USING:<br/>
public_factor_uses       USE:<br/>
public_factor_tuples   TUPLE:<br/>
public_factor_symbols SYMBOL:<br/>
public_factor_definitions   :<br/>
public_factor_definitions  ::<br/>
public_factor_definitions  M:<br/>
public_factor_definitions M::<br/>
</pre>

Also will index the header of a file that has the format:

<pre>
kMDItemDisplayName ! File: test.factor<br/>
kMDItemCopyright   ! Copyright (C) 2011 PolyMicro Systems<br/>
                   ! See http://factorcode.org/license.txt for BSD license.<br/>
kMDItemVersion     ! Version: 1.0<br/>
kMDItemAuthors     ! DRI: Dave Carlton<br>
kMDItemDescription ! Description: Defintions for testing Factor spotlight<br/>
</pre>
