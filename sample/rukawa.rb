require_relative './jobs/extension_sample'

Rukawa.configure do |c|
  c.graph.concentrate = true
  c.graph.nodesep = 0.8
  c.extensions << ExtensionSample
end
