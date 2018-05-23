# RPC using Anything But XML (RABX) message parser and emitter

[![Gem Version](https://badge.fury.io/rb/rabx-message.svg)](https://badge.fury.io/rb/rabx-message)
[![Build Status](https://secure.travis-ci.org/jpmckinney/rabx-message.png)](https://travis-ci.org/jpmckinney/rabx-message)
[![Coverage Status](https://coveralls.io/repos/jpmckinney/rabx-message/badge.png)](https://coveralls.io/r/jpmckinney/rabx-message)
[![Code Climate](https://codeclimate.com/github/jpmckinney/rabx-message.png)](https://codeclimate.com/github/jpmckinney/rabx-message)

The RABX specification is a [Perl module](https://github.com/mysociety/commonlib/blob/master/perllib/RABX.pm) by [mySociety](https://www.mysociety.org/).

## Usage

```ruby
require 'rabx/message'
```

Dump a RABX message:

```ruby
RABX::Message.dump('R', 'RPC.method', ['argument', 3])
# => "R1:0,10:RPC.method,L1:2,T8:argument,I1:3,"
RABX::Message.dump('S', {name: 'foo', email: 'foo@example.com'})
# => "S1:0,A1:2,T4:name,T3:foo,T5:email,T15:foo@example.com,"
RABX::Message.dump('E', 404, 'Not Found')
# => "E1:0,3:404,9:Not Found,N"
```

Load a RABX message:

```ruby
message = RABX::Message.load("R1:0,10:RPC.method,L1:2,T8:argument,I1:3,")
message.type # "R"
message.method # "RPC.method"
message.arguments # ["argument", 3]

message = RABX::Message.load("S1:0,A1:2,T4:name,T3:foo,T5:email,T15:foo@example.com,")
message.type # "S"
message.value # {"name"=>"foo", "email"=>"foo@example.com"}

message = RABX::Message.load("E1:0,3:404,9:Not Found,N")
message.type # "E"
message.code # "404"
message.text # "Not Found"
message.extra # nil
```

See the [documentation](http://www.rubydoc.info/gems/rabx-message) to see how to work with `RABX::Message` instances.

## Notes

Generic RABX clients include:

* [Perl](https://github.com/mysociety/commonlib/blob/master/perllib/RABX.pm)
* [PHP](https://github.com/mysociety/commonlib/blob/master/phplib/rabx.php)
* [Python](https://github.com/mysociety/commonlib/blob/master/pylib/mysociety/rabx.py) (REST interface)
* [Ruby](https://github.com/mysociety/commonlib/blob/master/rblib/rabx.rb) (REST interface)
* [Command-line](https://github.com/mysociety/misc-scripts/blob/master/bin/rabx)

mySociety has scripts to convert a Perl RABX server to a server-specific client in:

* [Perl](https://github.com/mysociety/misc-scripts/blob/master/bin/rabxtopl.pl)
* [PHP](https://github.com/mysociety/misc-scripts/blob/master/bin/rabxtophp.pl)
* [Python](https://github.com/mysociety/misc-scripts/blob/master/bin/rabxresttopy.pl)
* [Ruby](https://github.com/mysociety/misc-scripts/blob/master/bin/rabxresttorb.pl)

Copyright (c) 2014 James McKinney, released under the MIT license
