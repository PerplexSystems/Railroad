signature CONFIGURATION =
sig
  datatype Order = Sequenced | Randomized of int option

  datatype Setting = Order of Order | Output of TextIO.outstream

  type Configuration = {output: TextIO.outstream, order: Order}

  val ofList: Setting list -> Configuration
end

structure Configuration: CONFIGURATION =
struct
  datatype Order = Sequenced | Randomized of int option

  datatype Setting = Order of Order | Output of TextIO.outstream

  type Configuration = {output: TextIO.outstream, order: Order}

  val default = {output = TextIO.stdOut, order = Sequenced}

  fun ofList options =
    List.foldl
      (fn (opt, acc) =>
         case opt of
           Output output => {output = output, order = (#order acc)}
         | Order order => {output = (#output acc), order = order}) default
      options
end
