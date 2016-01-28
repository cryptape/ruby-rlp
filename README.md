# ruby-rlp

A Ruby implementation of Ethereum's Recursive Length Prefix encoding (RLP). You can find the specification of the standard in the [Ethereum wiki](https://github.com/ethereum/wiki/wiki/RLP).

## Benchmark

```
ruby-rlp $ ruby -v -Ilib test/speed.py
ruby 2.2.2p95 (2015-04-13 revision 50295) [x86_64-linux]
Block serializations / sec: 2318.21
Block deserializations / sec: 1704.61
TX serializations / sec: 30461.76
TX deserializations / sec: 21378.70

pyrlp $ python -V
Python 2.7.11

pyrlp $ PYTHONPATH=. python tests/speed.py
Block serializations / sec: 1225.00
Block deserializations / sec: 1162.01
TX serializations / sec: 16468.41
TX deserializations / sec: 14517.31
```
