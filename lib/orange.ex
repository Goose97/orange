defmodule Orange do
  defdelegate start(element), to: Orange.Runtime
  defdelegate stop(), to: Orange.Runtime
  defdelegate subscribe(component_id), to: Orange.Runtime
  defdelegate unsubscribe(component_id), to: Orange.Runtime
  defdelegate focus(component_id), to: Orange.Runtime
  defdelegate unfocus(component_id), to: Orange.Runtime
end
