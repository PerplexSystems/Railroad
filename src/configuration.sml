signature CONFIGURATION =
sig
  datatype Order = Sequenced | Randomized of int option

  datatype Configuration = Order of Order | Output of TextIO.outstream
end

structure Configuration =
struct
  datatype Order = Sequenced | Randomized of int option

  datatype Configuration = Order of Order | Output of TextIO.outstream

  type ConfigurationRecord = {output: TextIO.outstream, order: Order}

  val default = {output = TextIO.stdOut, order = Sequenced}

  fun ofList options =
    List.foldl
      (fn (opt, acc) =>
         case opt of
           Output output => {output = output, order = (#order acc)}
         | Order order => {output = (#output acc), order = order}) default
      options

end
