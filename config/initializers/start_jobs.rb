# File to try to start all the jobs of activated services during
# boot time.
#
Service.where(:active => true).each do |serv|
  serv.job_start
end