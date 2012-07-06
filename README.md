# procinfo

## Installation

		$ npm install procinfo

## Usage

		var procinfo = require('procinfo');
		
		procinfo.memory(pid, function(err, info) {
			console.log(procinfo.pretty_object(info));
		});