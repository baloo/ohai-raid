#  Copyright (c) 2011 Zenexity
# All rights reserved.
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of Zenexity nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ``AS IS'' AND ANY
# EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE REGENTS AND CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# OSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.




class RaidControllerMonitor3Ware < RaidControllerMonitor
  def initialize
    @bin = 'tw_cli' 
    if Ohai::Config["3ware"] and Ohai::Config["3ware"][:bin]
      @bin = Ohai::Config["3ware"][:bin]
    end

  end
  def populate device
    device[:array] = []

    lookup_bin

    controller = "c" + device[:vendor_index].to_s
    controller_output = self.test_controller(controller)
    
    device.update(controller_output)
  end

  def run arguments
    output = IO.popen(@bin + " " + arguments, 'r')
    output.readlines
  end

  def test_controller controller
    controller_output = Mash.new
    units = []
    drives = []
    run("/" + controller + " show").each do |line|
      case line
      when /^(u[0-9]+)/
        unit = Hash.new
        
        unit_name = Regexp.last_match(0) 
        line_elmts = line.split()
        
        state = line_elmts[2]
        case state
        when "OK"
          status = :normal
        when "REBUILDING", "VERIFY-PAUSED", "VERIFYING", "INITIALIZING"
          status = :warning
        else
          status = :critical
        end

        type = line_elmts[1]
        if not line_elmts[5] =~ /^\-/
          stripe = line_elmts[5]
          unit[:stripe] = stripe
        end
        if not line_elmts[6] =~ /^\-/
          size = {:size => line_elmts[6], :unit => "GB"}
          unit[:size] = size
        end
        if not line_elmts[7] =~ /^\-/
          cache = line_elmts[7]
          unit[:cache] = cache
        end

        unit[:name] = unit_name
        unit[:state] = state
        unit[:status] = status
        unit[:type] = type

        units << unit
      when /^(p[0-9]+)/
        drive = Hash.new
        
        drive_name = Regexp.last_match(0) 
        line_elmts = line.split()

        state      = line_elmts[1]
        size       = {:size => line_elmts[3], :unit => line_elmts[4]}
        unit       = line_elmts[2]
        iface_type = line_elmts[5]
        iface_id   = line_elmts[6]
        hw         = line_elmts[8]

        case state
        when "OK", "NOT-PRESENT"
          status = :normal
        else
          status = :critical
        end

        drive[:name]       = drive_name
        drive[:state]      = state
        drive[:status]     = status

        drive[:size]       = size
        drive[:array]      = unit
        drive[:hw]         = hw
        drive[:iface_id]   = iface_id
        drive[:iface_type] = iface_type

        drives << drive
      end
    end
    controller_output[:array] = units
    controller_output[:drives] = drives
    controller_output
  end

  def lookup_bin
    if File.exists?(@bin)
      if File.executable?(@bin)
        return @bin
      end
    end

    ENV['PATH'].split(':').each do |path|
      bin = path + '/' + @bin
      if File.exists?(bin)
        if File.executable?(bin)
          @bin = bin
          return @bin
        end
      end
    end

    raise "#{@bin} does not exists"
  end
end



