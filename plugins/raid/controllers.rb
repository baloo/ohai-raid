provides "raid/controllers"

class RaidControllerMonitor
  def initialize
    raise "RaidControllerMonitor can't be instanciate directly"
  end
end

require_plugin "raid::controllers::threeware"

device_index = Hash.new()

raid[:devices].each do |device|
  # Reindex devices
  if not device_index[device[:vendor]]
    device_index[device[:vendor]] = 0
  end
  device[:vendor_index] = device_index[device[:vendor]]
  device_index[device[:vendor]] += 1

  case device[:vendor]
  when "3ware Inc"
    parser = RaidControllerMonitor3Ware.new()
  else
    break
  end
  parser.populate(device)
end


