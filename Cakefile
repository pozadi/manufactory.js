{exec} = require 'child_process'
sys = require 'sys'

sources = 'src/core src/base-module src/module-info src/jquery-plugins'
output = 'manufactory'

testsSources = 'tests/tests'
testsOutput = 'tests/js'

run = (comand) ->
  child = exec comand
  child.stdout.on 'data', (data) -> sys.print data

task 'build', 'build things', ->
  run "coffee -c -j #{output} #{sources}"
  run "coffee -c -o #{testsOutput} #{testsSources}"


task 'watch', 'watch things to be updated', ->
  run "coffee -cw -j #{output} #{sources}"
  run "coffee -cw -o #{testsOutput} #{testsSources}"
