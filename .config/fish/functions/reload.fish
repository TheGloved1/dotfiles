function reload --wraps='exec fish' --description 'alias reload=exec fish'
  exec fish $argv
end
