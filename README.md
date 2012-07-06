# procinfo

## Installation

```bash
$ npm install procinfo
```

## Usage

```javascript
var procinfo = require('procinfo');

procinfo.memory(pid, function(err, info) {
	console.log(procinfo.pretty_object(info));
});
```
