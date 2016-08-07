defmodule Modbus.Request do
  import Modbus.Helper

  def pack({:rdo, slave, address, count}) do
    reads(:d, slave, 1, address, count)
  end

  def pack({:rdi, slave, address, count}) do
    reads(:d, slave, 2, address, count)
  end

  def pack({:rao, slave, address, count}) do
    reads(:a, slave, 3, address, count)
  end

  def pack({:rai, slave, address, count}) do
    reads(:a, slave, 4, address, count)
  end

  def pack({:wdo, slave, address, value}) when is_integer(value) do
    write(:d, slave, 5, address, value)
  end

  def pack({:wao, slave, address, value}) when is_integer(value) do
    write(:a, slave, 6, address, value)
  end

  def pack({:wdo, slave, address, values}) when is_list(values) do
    writes(:d, slave, 15, address, values)
  end

  def pack({:wao, slave, address, values}) when is_list(values) do
    writes(:a, slave, 16, address, values)
  end

  def parse(<<slave, 1, address::size(16), count::size(16), tail::binary>>) do
    {{:rdo, slave, address, count}, tail}
  end

  def parse(<<slave, 2, address::size(16), count::size(16), tail::binary>>) do
    {{:rdi, slave, address, count}, tail}
  end

  def parse(<<slave, 3, address::size(16), count::size(16), tail::binary>>) do
    {{:rao, slave, address, count}, tail}
  end

  def parse(<<slave, 4, address::size(16), count::size(16), tail::binary>>) do
    {{:rai, slave, address, count}, tail}
  end

  def parse(<<slave, 5, address::size(16), 0x00, 0x00, tail::binary>>) do
    {{:wdo, slave, address, 0}, tail}
  end

  def parse(<<slave, 5, address::size(16), 0xFF, 0x00, tail::binary>>) do
    {{:wdo, slave, address, 1}, tail}
  end

  def parse(<<slave, 6, address::size(16), value::size(16), tail::binary>>) do
    {{:wao, slave, address, value}, tail}
  end

  def parse(<<slave, 15, address::size(16), count::size(16), bytes, data::binary>>) do
    ^bytes = byte_count(count)
    {values, tail} = bin2bitlist(count, data)
    {{:wdo, slave, address, values}, tail}
  end

  def parse(<<slave, 16, address::size(16), count::size(16), bytes, data::binary>>) do
    ^bytes = 2 * count
    {values, tail} = bin2registerlist(count, data)
    {{:wao, slave, address, values}, tail}
  end

  defp reads(_type, slave, function, address, count) do
    <<slave, function, address::size(16), count::size(16)>>
  end

  defp write(:d, slave, function, address, value) do
    <<slave, function, address::size(16), bool_val(value), 0x00>>
  end

  defp write(:a, slave, function, address, value) do
    <<slave, function, address::size(16), value::size(16)>>
  end

  defp writes(:d, slave, function, address, values) do
    count =  Enum.count(values)
    bytes = byte_count(count)
    data = bitlist2bin(values)
    <<slave, function, address::size(16), count::size(16), bytes, data::binary>>
  end

  defp writes(:a, slave, function, address, values) do
    count =  Enum.count(values)
    bytes = 2 * count
    data = registerlist2bin(values)
    <<slave, function, address::size(16), count::size(16), bytes, data::binary>>
  end

end
