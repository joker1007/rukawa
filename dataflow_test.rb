require 'concurrent'

def fib(n)
  if n < 2
    Concurrent::dataflow! { n }
  else
    n1 = fib(n - 1)
    n2 = fib(n - 2)
    Concurrent::dataflow!(n1, n2) do |v1, v2|
      p (v1 + v2)
      (v1 + v2).tap {|val| raise "foo" if val == 13}
    end
  end
end

f = fib(14) #=> #<Concurrent::Future:0x000001019a26d8 ...
sleep(0.5)

p f.value #=> 377
raise f.reason
