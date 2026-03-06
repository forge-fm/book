open util/ordering[FA] as ordFA
open util/ordering[CLU] as ordCLU
open util/integer


//sigs

abstract sig Component {
cin: lone Int,
cout: lone Int,
unit_delay: Int,
input_delay_estimate: Int,
output_delay_estimate: Int,
actual_delay: Int,
succ: lone Component, 
}

sig FA extends Component {
  a, b,s: set Int,
  p,g,k:set Int
}

sig CLU extends Component{
    rca: seq FA 
}{
#rca=4
}

sig delay_calc{
CLA_path_delay_conservative: Int,
RCA_path_delay_conservative: Int,
CLA_path_delay_to_result: Int,
RCA_path_delay_to_result: Int,


}

pred f_next [f: FA]{
f.succ=f.next

}

pred clu_next[c:CLU]{
c.succ=c.next
}



fun adder_S_RCA[f: FA]: lone Int  {
  let A = some f.a, B = some f.b, CIN = some f.cin |
	 ((A and B and CIN) or (A and (not B) and (not CIN)) or ((not A) and B and (not CIN)) or ((not A) and (not B) and CIN))
	 	=> 1 else none 
	} 

fun adder_cout_RCA[f: FA]: lone Int {
 let A = some f.a, B = some f.b, CIN = some f.cin |
     ((not A and B and CIN) or (A and not B and CIN) or (A and B and not CIN) or (A and B and CIN)) 
	=> 1 else none  
} 

fun adder_g[f: FA]: lone Int{
  let A = some f.a, B = some f.b|
	 ((A and B))
	 => 1 else none 
}

fun adder_p[f: FA]: lone Int{
  let A = some f.a, B = some f.b|
	 ((A and (not B)) or ((not A) and B))
	 => 1 else none 
}

fun adder_k[f: FA]: lone Int{
  let A = some f.a, B = some f.b|
	 ((not A) and (not B))
	 => 1 else none 
}

fun CLU_cout[f:CLU]: lone Int {
   let  CIN = some f.rca.first.cin, G0=some f.rca.first.g, G1= some f.rca.first.next.g, G2 = some f.rca.first.next.next.g, G3 = some f.rca.last.g,
 	P0=some f.rca.first.next.p, P1= some f.rca.first.next.p, P2=some f.rca.first.next.next.p, P3= some f.rca.last.p |
	//{(f in s.working)=>( //maybe f in sworking or s.done	
 		(((CIN and (P0 and P1 and P2 and P3)) or ((((((G0 and P1) or G1) and P2) or G2) and P3)or G3))	
   		=>1 else none)
	//		else none
// }
 }

pred add_per_unit[f: FA]{
f.s=adder_S_RCA[f]
f.cout=adder_cout_RCA[f]

}

fun rca_delay[f:FA]: Int{
  let S=some f.s, C=some f.cout|
 	((S or C) or (S and C)) => 
	f.unit_delay
	else 0
	
}

fun clu_delay[c:CLU]: Int{
  let cout=some c.cout |
 	(cout) => 
	c.unit_delay
	else 0
	
}

fact{
all f: FA |{
 add_per_unit[f]
 f_next[f]
 f.unit_delay=1
 f.p=adder_p[f]
 f.g=adder_g[f]
 f.k=adder_k[f]

}


all c: CLU |{
clu_next[c]

c.cout=CLU_cout[c]
c.rca[1]=c.rca[0].next
c.rca[1].cin=c.rca[0].cout

c.rca[2]=c.rca[1].next
c.rca[2].cin=c.rca[1].cout

c.rca[3]=c.rca[2].next
c.rca[3].cin=c.rca[2].cout

c.next.rca[0]=c.rca[3].next
c.next.rca[0].cin=c.cout

c.next.cin=c.cout
}

ordFA/first.cin=none
ordCLU/first.cin=none
ordCLU/first.unit_delay=3
ordCLU/first.input_delay_estimate=0
ordFA/first.input_delay_estimate=0
ordCLU/first.output_delay_estimate=ordCLU/first.unit_delay
ordFA/first.output_delay_estimate=ordFA/first.unit_delay
ordFA/first.actual_delay=rca_delay[ordFA/first]
ordCLU/first.actual_delay=clu_delay[ordCLU/first]
all c:CLU-ordCLU/first|{
c.unit_delay=0
}

all c1,c2: CLU | {
 c2 in c1.succ implies {
	c2.input_delay_estimate = c1.output_delay_estimate
	c2.output_delay_estimate = add[c2.input_delay_estimate,c2.unit_delay]
	c2.actual_delay=add[c1.actual_delay,clu_delay[c2]]
	}
}

all c1,c2: FA | {
 c2 in c1.succ implies {
	c2.input_delay_estimate = c1.output_delay_estimate
 	c2.output_delay_estimate = add[c2.input_delay_estimate,c2.unit_delay]
                  c2.actual_delay=add[c1.actual_delay,rca_delay[c2]]
	}
}


delay_calc.CLA_path_delay_conservative=add[div[ordFA/last.output_delay_estimate,#CLU],ordCLU/last.output_delay_estimate]
delay_calc.RCA_path_delay_conservative=ordFA/last.output_delay_estimate
delay_calc.RCA_path_delay_to_result=ordFA/last.actual_delay
delay_calc.CLA_path_delay_to_result=add[
			 div[delay_calc.RCA_path_delay_conservative,#CLU],

			ordCLU/last.actual_delay]
}



pred a1{

ordCLU/first.rca[0].a=1
ordCLU/first.rca[0].b=1
ordCLU/first.rca[1].a=1
ordCLU/first.rca[1].b=1
ordCLU/first.rca[2].a=1
ordCLU/first.rca[2].b=1
ordCLU/first.rca[3].a=none
ordCLU/first.rca[3].b=none


ordCLU/first.next.rca[0].a=none
ordCLU/first.next.rca[0].b=none
ordCLU/first.next.rca[1].a=none
ordCLU/first.next.rca[1].b=none
ordCLU/first.next.rca[2].a=none
ordCLU/first.next.rca[2].b=none
ordCLU/first.next.rca[3].a=none
ordCLU/first.next.rca[3].b=none

}



run {a1} for 8 FA, 2 CLU, 4 seq, 1 delay_calc, 6 int //, 20 Time

