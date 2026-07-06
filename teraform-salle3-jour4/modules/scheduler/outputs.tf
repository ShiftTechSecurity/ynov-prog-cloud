output "schedule_enabled" {
  value = var.enable_schedule
}

output "schedule_names" {
  value = var.enable_schedule ? {
    stop  = aws_scheduler_schedule.stop[0].name
    start = aws_scheduler_schedule.start[0].name
  } : {}
}
