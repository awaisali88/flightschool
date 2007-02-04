module BillingHelper

def format_hobbs x
  Kernel.sprintf "%.1f",((x/100.0)-(x/100.0).floor)*100
end

end
