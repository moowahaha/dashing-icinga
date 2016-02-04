require 'aws'

cloudwatch = nil

SCHEDULER.every '2m', first_in: 0 do |job|

  cloudwatch ||= AWS::CloudWatch::Client.new(
      region: settings.aws_region,
      access_key_id: settings.aws_access_key_id,
      secret_access_key: settings.aws_secret_access_key
  )

  ok_alarm_counter = 0
  total_alarms = 0
  triggered_alarms = []
  triggered_alarms_counter = 0

  response = cloudwatch.describe_alarms
  response.metric_alarms.each do |alarm|
    total_alarms += 1

    if alarm[:state_value] == 'OK'
      ok_alarm_counter += 1
    else
      triggered_alarms << "#{alarm[:alarm_name]} (#{alarm[:state_value]})"
      triggered_alarms_counter += 1
    end
  end

  color = triggered_alarms.empty? ? 'green' : 'red'

  send_event "cloudwatch-alarms-ok", {value: "#{ok_alarm_counter}/#{total_alarms}", color: color}
  send_event "cloudwatch-alarms-failed", {
                                           value: triggered_alarms.join(' | '),
                                           moreinfo: "#{triggered_alarms_counter} problems",
                                           color: color
                                       }
end