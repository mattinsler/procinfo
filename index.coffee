os = require 'os'
fs = require 'fs'
child_process = require 'child_process'

parse_fields = (obj) ->
  for k, v of obj
    obj[k] = v = v.replace(/(^[ \t\r\n]+|[ \t\r\n]+$)/g, '')
    if parseInt(v).toString() is v
      obj[k] = parseInt(v)
    else if parseFloat(v).toString() is v
      obj[k] = parseFloat(v)
  obj

parse_ps = (pid, fields, callback) ->
  child_process.exec "ps -p #{pid} -o #{fields.join(',')}", (err, stdout, stderr) ->
    return callback(err) if err?
    
    headers = []
    [header_line, values_line] = stdout.split('\n')
    for x in [0...header_line.length]
      headers.push(x) if x > 0 and header_line[x] is ' ' and header_line[x - 1] isnt ' '

    o = {}
    for x in [0...fields.length]
      o[fields[x]] = values_line.substring((if x is 0 then 0 else headers[x - 1]), headers[x])

    callback(null, parse_fields(o))

PLATFORMS = {
  darwin: {
    memory: (pid, callback) ->
      fields = [
        'rss',  # resident set size
        'tsiz', # text size in Kbytes
        'vsz'   # virtual size in Kbytes
      ]
      
      parse_ps pid, fields, (err, stats) ->
        return callback(err) if err?
        callback(null, {
          resident: stats.rss * 1024
          text: stats.tsiz * 1024
          virtual: stats.vsz * 1024
        })
      
      null
  },
  linux: {
    stats: (pid, callback) ->
      fs.readFile "/proc/#{pid}/stat", 'utf8', (err, data) ->
        return callback(err) if err?
        
        o = {}
        [
          o.pid,
          o.comm,
          o.state,
          o.ppid,
          o.pgrp,
          o.session,
          o.tty_nr,
          o.tpgid,
          o.flags,
          o.minflt,
          o.cminflt,
          o.majflt,
          o.cmajflt,
          o.utime,
          o.stime,
          o.cutime,
          o.cstime,
          o.priority,
          o.nice,
          o.num_threads,
          o.itrealvalue,
          o.starttime,
          o.vsize,
          o.rss,
          o.rsslim,
          o.startcode,
          o.endcode,
          o.startstack,
          o.kstkesp,
          o.kstkeip,
          o.signal,
          o.blocked,
          o.sigignore,
          o.sigcatch,
          o.wchan,
          o.nswap,
          o.cnswap,
          o.exit_signal,
          o.processor,
          o.rt_priority,
          o.policy,
          o.delayacct_blkio_ticks,
          o.guest_time,
          o.cguest_time
        ] = data.split(' ')
        
        for k in Object.keys(o) when k isnt 'comm'
          o[k] = parseInt(o[k])

        callback(null, o)
  
    memory: (pid, callback) ->
      fs.readFile "/proc/#{pid}/statm", 'utf8', (err, data) ->
        return callback(err) if err?
        
        o = {}
        [
          o.size,
          o.resident,
          o.share,
          o.text,
          o.lib,
          o.data,
          o.dt
        ] = data.split(' ')

        callback(null, {
          resident: o.resident * 4096
          text: o.text * 4096
          virtual: o.size * 4096
          shared_pages: o.share * 4096
          data: o.data * 4096
        })
  }
}

exports.memory = (pid, callback) ->
  PLATFORMS[os.platform()].memory(pid, callback)

exports.pretty = (value) ->
  if value < (1024 * 1024)
    "#{Math.floor(100 * value / 1024) / 100} KB"
  else
    "#{Math.floor(100 * value / (1024 * 1024)) / 100} MB"

exports.pretty_object = (obj) ->
  o = {}
  for k, v of obj
    o[k] = exports.pretty(v)
  o
