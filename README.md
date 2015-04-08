# experimental copy of analyzer

This code is an experimental version of the Dart analyzer package, with
changes needed for the
[dart-dev-compiler](https://github.com/dart-lang/dart-dev-compiler).

The code in this repo is not meant to be published as a package in
pub.dartlang.org, and it's only meant to be temporary. Our intention is to port
these changes back to the original analyzer package as we evolve in exploring
our options and better understand what changes are necessary.

Having this code in it's own repo makes it much easier to track what
changes we've made. We use the `master` branch for our latest changes, and use
`upstream` to point to a fixed version of the analyzer package. See these [notes](https://github.com/dart-lang/ddc_analyzer/wiki) for details on how we roll changes when a new version of analyzer is released.


## original README from analyzer:
This code is part of an experimental port of the Editor's analysis engine from
Java to Dart. While we will continue to support the Java version of the analysis
engine and the services built on it, we also intend to provide the same services
to Dart-based applications. This is very early code and we expect it to change,
possibly in significant ways. While we are eager to see other people make use
of the analysis engine, we also want to be clear, in case you are interested in
doing so, that the current API's should in no way be considered to be stable.

In particular, this code was automatically translated from the Java
implementation. The Java implementation that was translated is still under
development and will continue to change over time. The translator that was used
is still under development and the output produced by the translator will change
over time. Therefore, the API presented by this code will change. In addition,
any edits made to this code will be overwritten the next time we re-generate
this code.

If you are interested in using this code, despite the disclaimer above,
fantastic! Please let the editor team know so that we can get a sense of the
interest in it. Also, feel free to ask questions and make requests for
additional functionality.
