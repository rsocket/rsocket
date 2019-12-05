# Well-known Authentication Types

## Introduction
The [Authentication Extension][a] provides a standardized mechanism for including both the type of credentials and the credentials in metadata payloads. Authentication Types define how to read the Authentication Payload. However, due to their definitions as strings and the number of times they need to be sent as part of typical interaction, they can be wasteful in their typical form.  Because of this, it's useful to represent well-known Authentication Types as integer values during transmission.  This behavior does not remove the need or ability in the specifications to declare Authentication Types as strings.

[a]: Authentication.md

## Mappings
All well-known Authentication Types assume UTF-8 character encoding wherever a character set might be necessary.  If another character set is required, a string-based Authentication Type should be used.

| Auth Type | Identifier
| --------- | ----------
| [`simple`][simple] | `0x00`
| [`bearer`][bearer] | `0x01`

[simple]: Simple.md
[bearer]: Bearer.md