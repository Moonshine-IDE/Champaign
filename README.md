# Champaign

Haxe library to extend functionality with low and high level system API's.

### Installation

```
haxelib git champaign https://github.com/Moonshine-IDE/Champaign.git
```

### Updating Champaign

```
haxelib update champaign
```

### Using Champaign

#### Haxe (hxml)

Add Champaign as a library in your hxml file

```
--library champaign
```

Or in an OpenFL project.xml file

```xml
<haxelib name="champaign" />
```

### API Docs

[https://moonshine-ide.github.io/Champaign/api/](https://moonshine-ide.github.io/Champaign/api/)


### Logging

Logging may be controlled with compilation flags:

Flag | Description
-- | --
CHAMPAIGN_DEBUG | Log general activity from library
CHAMPAIGN_VERBOSE | Detailed logs - may generate a large amount of log output
LOG_CHAMPAIGN_EXCEPTION | Log exceptions within the library

This may eventually be changed to be based on more standardized log levels.
