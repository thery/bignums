(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2016     *)
(*   \VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)
(*            Benjamin Gregoire, Laurent Thery, INRIA, 2007             *)
(************************************************************************)

(*S NMake_gen.ml : this file generates NMake_gen.v *)


(*s The parameter that control the generation: *)

let size = 6 (* how many times should we repeat the Z/nZ --> Z/2nZ
                process before relying on a generic construct *)

(*s Some utilities *)

let rec iter_str n s = if n = 0 then "" else (iter_str (n-1) s) ^ s

let rec iter_str_gen n f = if n < 0 then "" else (iter_str_gen (n-1) f) ^ (f n)

let rec iter_name i j base sep =
  if i >= j then base^(string_of_int i)
  else (iter_name i (j-1) base sep)^sep^" "^base^(string_of_int j)

let pr s = Printf.printf (s^^"\n")

(*s The actual printing *)

let _ =

pr
"(************************************************************************)
(*  v      *   The Coq Proof Assistant  /  The Coq Development Team     *)
(* <O___,, *   INRIA - CNRS - LIX - LRI - PPS - Copyright 1999-2010     *)
(*   \\VV/  **************************************************************)
(*    //   *      This file is distributed under the terms of the       *)
(*         *       GNU Lesser General Public License Version 2.1        *)
(************************************************************************)
(*            Benjamin Gregoire, Laurent Thery, INRIA, 2007             *)
(************************************************************************)

(** * NMake_gen *)

(** From a cyclic Z/nZ representation to arbitrary precision natural numbers.*)

(** Remark: File automatically generated by NMake_gen.ml, DO NOT EDIT ! *)

Require Import BigNumPrelude ZArith Ndigits CyclicAxioms
 DoubleType DoubleMul DoubleDivn1 DoubleCyclic Nbasic
 Wf_nat StreamMemo.

Module Make (W0:CyclicType) <: NAbstract.

 (** * The word types *)
";

pr " Local Notation w0 := W0.t.";
for i = 1 to size do
  pr " Definition w%i := zn2z w%i." i (i-1)
done;
pr "";

pr " (** * The operation type classes for the word types *)
";

pr " Local Notation w0_op := W0.ops.";
for i = 1 to min 3 size do
  pr " Instance w%i_op : ZnZ.Ops w%i := mk_zn2z_ops w%i_op." i i (i-1)
done;
for i = 4 to size do
  pr " Instance w%i_op : ZnZ.Ops w%i := mk_zn2z_ops_karatsuba w%i_op." i i (i-1)
done;
for i = size+1 to size+3 do
  pr " Instance w%i_op : ZnZ.Ops (word w%i %i) := mk_zn2z_ops_karatsuba w%i_op." i size (i-size) (i-1)
done;
pr "";

  pr " Section Make_op.";
  pr "  Variable mk : forall w', ZnZ.Ops w' -> ZnZ.Ops (zn2z w').";
  pr "";
  pr "  Fixpoint make_op_aux (n:nat) : ZnZ.Ops (word w%i (S n)):=" size;
  pr "   match n return ZnZ.Ops (word w%i (S n)) with" size;
  pr "   | O => w%i_op" (size+1);
  pr "   | S n1 =>";
  pr "     match n1 return ZnZ.Ops (word w%i (S (S n1))) with" size;
  pr "     | O => w%i_op" (size+2);
  pr "     | S n2 =>";
  pr "       match n2 return ZnZ.Ops (word w%i (S (S (S n2)))) with" size;
  pr "       | O => w%i_op" (size+3);
  pr "       | S n3 => mk _ (mk _ (mk _ (make_op_aux n3)))";
  pr "       end";
  pr "     end";
  pr "   end.";
  pr "";
  pr " End Make_op.";
  pr "";
  pr " Definition omake_op := make_op_aux mk_zn2z_ops_karatsuba.";
  pr "";
  pr "";
  pr " Definition make_op_list := dmemo_list _ omake_op.";
  pr "";
  pr " Instance make_op n : ZnZ.Ops (word w%i (S n))" size;
  pr "  := dmemo_get _ omake_op n make_op_list.";
  pr "";

pr " Ltac unfold_ops := unfold omake_op, make_op_aux, w%i_op, w%i_op." (size+3) (size+2);

pr
"
 Lemma make_op_omake: forall n, make_op n = omake_op n.
 Proof.
 intros n; unfold make_op, make_op_list.
 refine (dmemo_get_correct _ _ _).
 Qed.

 Theorem make_op_S: forall n,
   make_op (S n) = mk_zn2z_ops_karatsuba (make_op n).
 Proof.
 intros n. do 2 rewrite make_op_omake.
 revert n. fix IHn 1.
 do 3 (destruct n; [unfold_ops; reflexivity|]).
 simpl mk_zn2z_ops_karatsuba. simpl word in *.
 rewrite <- (IHn n). auto.
 Qed.

 (** * The main type [t], isomorphic with [exists n, word w0 n] *)
";

  pr " Inductive t' :=";
  for i = 0 to size do
    pr "  | N%i : w%i -> t'" i i
  done;
  pr "  | Nn : forall n, word w%i (S n) -> t'." size;
  pr "";
  pr " Definition t := t'.";
  pr "";

  pr " (** * A generic toolbox for building and deconstructing [t] *)";
  pr "";

  pr " Local Notation SizePlus n := %sn%s."
    (iter_str size "(S ") (iter_str size ")");
  pr " Local Notation Size := (SizePlus O).";
  pr "";

  pr " Tactic Notation (at level 3) \"do_size\" tactic3(t) := do %i t." (size+1);
  pr "";

  pr " Definition dom_t n := match n with";
  for i = 0 to size do
    pr "  | %i => w%i" i i;
  done;
  pr "  | %sn => word w%i n" (if size=0 then "" else "SizePlus ") size;
  pr " end.";
  pr "";

pr
" Instance dom_op n : ZnZ.Ops (dom_t n) | 10.
 Proof.
  do_size (destruct n; [simpl;auto with *|]).
  unfold dom_t. auto with *.
 Defined.
";

  pr " Definition iter_t {A:Type}(f : forall n, dom_t n -> A) : t -> A :=";
  for i = 0 to size do
   pr "  let f%i := f %i in" i i;
  done;
  pr "  let fn n := f (SizePlus (S n)) in";
  pr "  fun x => match x with";
  for i = 0 to size do
    pr "   | N%i wx => f%i wx" i i;
  done;
  pr "   | Nn n wx => fn n wx";
  pr "  end.";
  pr "";

  pr " Definition mk_t (n:nat) : dom_t n -> t :=";
  pr "  match n as n' return dom_t n' -> t with";
  for i = 0 to size do
    pr "   | %i => N%i" i i;
  done;
  pr "   | %s(S n) => Nn n" (if size=0 then "" else "SizePlus ");
  pr "  end.";
  pr "";

pr
" Definition level := iter_t (fun n _ => n).

 Inductive View_t : t -> Prop :=
  Mk_t : forall n (x : dom_t n), View_t (mk_t n x).

 Lemma destr_t : forall x, View_t x.
 Proof.
 intros x. generalize (Mk_t (level x)). destruct x; simpl; auto.
 Defined.

 Lemma iter_mk_t : forall A (f:forall n, dom_t n -> A),
 forall n x, iter_t f (mk_t n x) = f n x.
 Proof.
 do_size (destruct n; try reflexivity).
 Qed.

 (** * Projection to ZArith *)

 Definition to_Z : t -> Z :=
  Eval lazy beta iota delta [iter_t dom_t dom_op] in
  iter_t (fun _ x => ZnZ.to_Z x).

 Notation \"[ x ]\" := (to_Z x).

 Theorem spec_mk_t : forall n (x:dom_t n), [mk_t n x] = ZnZ.to_Z x.
 Proof.
 intros. change to_Z with (iter_t (fun _ x => ZnZ.to_Z x)).
 rewrite iter_mk_t; auto.
 Qed.

 (** * Regular make op, without memoization or karatsuba

     This will normally never be used for actual computations,
     but only for specification purpose when using
     [word (dom_t n) m] intermediate values. *)

 Fixpoint nmake_op (ww:Type) (ww_op: ZnZ.Ops ww) (n: nat) :
       ZnZ.Ops (word ww n) :=
  match n return ZnZ.Ops (word ww n) with
   O => ww_op
  | S n1 => mk_zn2z_ops (nmake_op ww ww_op n1)
  end.

 Definition eval n m := ZnZ.to_Z (Ops:=nmake_op _ (dom_op n) m).

 Theorem nmake_op_S: forall ww (w_op: ZnZ.Ops ww) x,
   nmake_op _ w_op (S x) = mk_zn2z_ops (nmake_op _ w_op x).
 Proof.
 auto.
 Qed.

 Theorem digits_nmake_S :forall n ww (w_op: ZnZ.Ops ww),
    ZnZ.digits (nmake_op _ w_op (S n)) =
    xO (ZnZ.digits (nmake_op _ w_op n)).
 Proof.
 auto.
 Qed.

 Theorem digits_nmake : forall n ww (w_op: ZnZ.Ops ww),
    ZnZ.digits (nmake_op _ w_op n) = Pos.shiftl_nat (ZnZ.digits w_op) n.
 Proof.
 induction n. auto.
 intros ww ww_op. rewrite Pshiftl_nat_S, <- IHn; auto.
 Qed.

 Theorem nmake_double: forall n ww (w_op: ZnZ.Ops ww),
    ZnZ.to_Z (Ops:=nmake_op _ w_op n) =
    @DoubleBase.double_to_Z _ (ZnZ.digits w_op) (ZnZ.to_Z (Ops:=w_op)) n.
 Proof.
 intros n; elim n; auto; clear n.
 intros n Hrec ww ww_op; simpl DoubleBase.double_to_Z; unfold zn2z_to_Z.
 rewrite <- Hrec; auto.
 unfold DoubleBase.double_wB; rewrite <- digits_nmake; auto.
 Qed.

 Theorem nmake_WW: forall ww ww_op n xh xl,
  (ZnZ.to_Z (Ops:=nmake_op ww ww_op (S n)) (WW xh xl) =
   ZnZ.to_Z (Ops:=nmake_op ww ww_op n) xh *
    base (ZnZ.digits (nmake_op ww ww_op n)) +
   ZnZ.to_Z (Ops:=nmake_op ww ww_op n) xl)%%Z.
 Proof.
 auto.
 Qed.

 (** * The specification proofs for the word operators *)
";

  if size <> 0 then
  pr " Typeclasses Opaque %s." (iter_name 1 size "w" "");
  pr "";

  pr " Instance w0_spec: ZnZ.Specs w0_op := W0.specs.";
  for i = 1 to min 3 size do
    pr " Instance w%i_spec: ZnZ.Specs w%i_op := mk_zn2z_specs w%i_spec." i i (i-1)
  done;
  for i = 4 to size do
    pr " Instance w%i_spec: ZnZ.Specs w%i_op := mk_zn2z_specs_karatsuba w%i_spec." i i (i-1)
  done;
  pr " Instance w%i_spec: ZnZ.Specs w%i_op := mk_zn2z_specs_karatsuba w%i_spec." (size+1) (size+1) size;


pr "
 Instance wn_spec (n:nat) : ZnZ.Specs (make_op n).
 Proof.
  induction n.
  rewrite make_op_omake; simpl; auto with *.
  rewrite make_op_S. exact (mk_zn2z_specs_karatsuba IHn).
 Qed.

 Instance dom_spec n : ZnZ.Specs (dom_op n) | 10.
 Proof.
  do_size (destruct n; auto with *). apply wn_spec.
 Qed.

 Let make_op_WW : forall n x y,
   (ZnZ.to_Z (Ops:=make_op (S n)) (WW x y) =
    ZnZ.to_Z (Ops:=make_op n) x * base (ZnZ.digits (make_op n))
     + ZnZ.to_Z (Ops:=make_op n) y)%%Z.
 Proof.
 intros n x y; rewrite make_op_S; auto.
 Qed.

 (** * Zero *)

 Definition zero0 : w0 := ZnZ.zero.

 Definition zeron n : dom_t n :=
  match n with
   | O => zero0
   | SizePlus (S n) => W0
   | _ => W0
  end.

 Lemma spec_zeron : forall n, ZnZ.to_Z (zeron n) = 0%%Z.
 Proof.
   do_size (destruct n;
            [match goal with
             |- @eq Z (_ (zeron ?n)) _ => 
               apply (ZnZ.spec_0 (Specs:=dom_spec n))
             end|]).
  destruct n; auto. simpl. rewrite make_op_S. fold word. 
  apply (ZnZ.spec_0 (Specs:=wn_spec (SizePlus 0))).
 Qed.

 (** * Digits *)

 Lemma digits_make_op_0 : forall n,
  ZnZ.digits (make_op n) = Pos.shiftl_nat (ZnZ.digits (dom_op Size)) (S n).
 Proof.
 induction n.
 auto.
 replace (ZnZ.digits (make_op (S n))) with (xO (ZnZ.digits (make_op n))).
  rewrite IHn; auto.
 rewrite make_op_S; auto.
 Qed.

 Lemma digits_make_op : forall n,
  ZnZ.digits (make_op n) = Pos.shiftl_nat (ZnZ.digits w0_op) (SizePlus (S n)).
 Proof.
 intros. rewrite digits_make_op_0.
 replace (SizePlus (S n)) with (S n + Size) by (rewrite <- plus_comm; auto).
 rewrite Pshiftl_nat_plus. auto.
 Qed.

 Lemma digits_dom_op : forall n,
  ZnZ.digits (dom_op n) = Pos.shiftl_nat (ZnZ.digits w0_op) n.
 Proof.
 do_size (destruct n; try reflexivity).
 exact (digits_make_op n).
 Qed.

 Lemma digits_dom_op_nmake : forall n m,
  ZnZ.digits (dom_op (m+n)) = ZnZ.digits (nmake_op _ (dom_op n) m).
 Proof.
 intros. rewrite digits_nmake, 2 digits_dom_op. apply Pshiftl_nat_plus.
 Qed.

 (** * Conversion between [zn2z (dom_t n)] and [dom_t (S n)].

     These two types are provably equal, but not convertible,
     hence we need some work. We now avoid using generic casts
     (i.e. rewrite via proof of equalities in types), since
     proving things with them is a mess.
 *)

 Definition succ_t n : zn2z (dom_t n) -> dom_t (S n) :=
  match n with
   | SizePlus (S _) => fun x => x
   | _ => fun x => x
  end.

 Lemma spec_succ_t : forall n x,
  ZnZ.to_Z (succ_t n x) =
  zn2z_to_Z (base (ZnZ.digits (dom_op n))) ZnZ.to_Z x.
 Proof.
 do_size (destruct n ; [reflexivity|]).
 intros. simpl. rewrite make_op_S. simpl. auto.
 Qed.

 Definition pred_t n : dom_t (S n) -> zn2z (dom_t n) :=
  match n with
   | SizePlus (S _) => fun x => x
   | _ => fun x => x
  end.

 Lemma succ_pred_t : forall n x, succ_t n (pred_t n x) = x.
 Proof.
 do_size (destruct n ; [reflexivity|]). reflexivity.
 Qed.

 (** We can hence project from [zn2z (dom_t n)] to [t] : *)

 Definition mk_t_S n (x : zn2z (dom_t n)) : t :=
  mk_t (S n) (succ_t n x).

 Lemma spec_mk_t_S : forall n x,
  [mk_t_S n x] = zn2z_to_Z (base (ZnZ.digits (dom_op n))) ZnZ.to_Z x.
 Proof.
 intros. unfold mk_t_S. rewrite spec_mk_t. apply spec_succ_t.
 Qed.

 Lemma mk_t_S_level : forall n x, level (mk_t_S n x) = S n.
 Proof.
 intros. unfold mk_t_S, level. rewrite iter_mk_t; auto.
 Qed.

 (** * Conversion from [word (dom_t n) m] to [dom_t (m+n)].

     Things are more complex here. We start with a naive version
     that breaks zn2z-trees and reconstruct them. Doing this is
     quite unfortunate, but I don't know how to fully avoid that.
     (cast someday ?). Then we build an optimized version where
     all basic cases (n<=6 or m<=7) are nicely handled.
 *)

 Definition zn2z_map {A} {B} (f:A->B) (x:zn2z A) : zn2z B :=
  match x with
   | W0 => W0
   | WW h l => WW (f h) (f l)
  end.

 Lemma zn2z_map_id : forall A f (x:zn2z A), (forall u, f u = u) ->
   zn2z_map f x = x.
 Proof.
  destruct x; auto; intros.
  simpl; f_equal; auto.
 Qed.

 (** The naive version *)

 Fixpoint plus_t n m : word (dom_t n) m -> dom_t (m+n) :=
  match m as m' return word (dom_t n) m' -> dom_t (m'+n) with
   | O => fun x => x
   | S m => fun x => succ_t _ (zn2z_map (plus_t n m) x)
  end.

 Theorem spec_plus_t : forall n m (x:word (dom_t n) m),
  ZnZ.to_Z (plus_t n m x) = eval n m x.
 Proof.
 unfold eval.
 induction m.
 simpl; auto.
 intros.
 simpl plus_t; simpl plus. rewrite spec_succ_t.
 destruct x.
 simpl; auto.
 fold word in w, w0.
 simpl. rewrite 2 IHm. f_equal. f_equal. f_equal.
 apply digits_dom_op_nmake.
 Qed.

 Definition mk_t_w n m (x:word (dom_t n) m) : t :=
   mk_t (m+n) (plus_t n m x).

 Theorem spec_mk_t_w : forall n m (x:word (dom_t n) m),
  [mk_t_w n m x] = eval n m x.
 Proof.
 intros. unfold mk_t_w. rewrite spec_mk_t. apply spec_plus_t.
 Qed.

 (** The optimized version.

     NB: the last particular case for m could depend on n,
     but it's simplier to just expand everywhere up to m=7
     (cf [mk_t_w'] later).
 *)

 Definition plus_t' n : forall m, word (dom_t n) m -> dom_t (m+n) :=
   match n return (forall m, word (dom_t n) m -> dom_t (m+n)) with
     | SizePlus (S n') as n => plus_t n
     | _ as n =>
         fun m => match m return (word (dom_t n) m -> dom_t (m+n)) with
                    | SizePlus (S (S m')) as m => plus_t n m
                    | _ => fun x => x
                  end
   end.

 Lemma plus_t_equiv : forall n m x,
  plus_t' n m x = plus_t n m x.
 Proof.
  (do_size try destruct n); try reflexivity;
   (do_size try destruct m); try destruct m; try reflexivity;
     simpl; symmetry; repeat (intros; apply zn2z_map_id; trivial).
 Qed.

 Lemma spec_plus_t' : forall n m x,
  ZnZ.to_Z (plus_t' n m x) = eval n m x.
 Proof.
 intros; rewrite plus_t_equiv. apply spec_plus_t.
 Qed.

 (** Particular cases [Nk x] = eval i j x with specific k,i,j
     can be solved by the following tactic *)

 Ltac solve_eval :=
  intros; rewrite <- spec_plus_t'; unfold to_Z; simpl dom_op; reflexivity.

 (** The last particular case that remains useful *)

 Lemma spec_eval_size : forall n x, [Nn n x] = eval Size (S n) x.
 Proof.
 induction n.
 solve_eval.
 destruct x as [ | xh xl ].
  simpl. unfold eval. rewrite make_op_S. rewrite nmake_op_S. auto.
 simpl word in xh, xl |- *.
 unfold to_Z in *. rewrite make_op_WW.
 unfold eval in *. rewrite nmake_WW.
 f_equal; auto.
 f_equal; auto.
 f_equal.
 rewrite <- digits_dom_op_nmake. rewrite plus_comm; auto.
 Qed.

 (** An optimized [mk_t_w].

     We could say mk_t_w' := mk_t _ (plus_t' n m x)
     (TODO: WHY NOT, BTW ??).
     Instead we directly define functions for all intersting [n],
     reverting to naive [mk_t_w] at places that should normally
     never be used (see [mul] and [div_gt]).
 *)
";

for i = 0 to size-1 do
let pattern = (iter_str (size+1-i) "(S ") ^ "_" ^ (iter_str (size+1-i) ")") in
pr
" Definition mk_t_%iw m := Eval cbv beta zeta iota delta [ mk_t plus ] in
  match m return word w%i (S m) -> t with
    | %s as p => mk_t_w %i (S p)
    | p => mk_t (%i+p)
  end.
" i i pattern i (i+1)
done;

pr
" Definition mk_t_w' n : forall m, word (dom_t n) (S m) -> t :=
  match n return (forall m, word (dom_t n) (S m) -> t) with";
for i = 0 to size-1 do pr "    | %i => mk_t_%iw" i i done;
pr
"    | Size => Nn
    | _ as n' => fun m => mk_t_w n' (S m)
  end.
";

pr
" Ltac solve_spec_mk_t_w' :=
  rewrite <- spec_plus_t';
  match goal with _ : word (dom_t ?n) ?m |- _ => apply (spec_mk_t (n+m)) end.

 Theorem spec_mk_t_w' :
  forall n m x, [mk_t_w' n m x] = eval n (S m) x.
 Proof.
 intros.
 repeat (apply spec_mk_t_w || (destruct n;
  [repeat (apply spec_mk_t_w || (destruct m; [solve_spec_mk_t_w'|]))|])).
 apply spec_eval_size.
 Qed.

 (** * Extend : injecting [dom_t n] into [word (dom_t n) (S m)] *)

 Definition extend n m (x:dom_t n) : word (dom_t n) (S m) :=
  DoubleBase.extend_aux m (WW (zeron n) x).

 Lemma spec_extend : forall n m x,
  [mk_t n x] = eval n (S m) (extend n m x).
 Proof.
 intros. unfold eval, extend.
 rewrite spec_mk_t.
 assert (H : forall (x:dom_t n),
              (ZnZ.to_Z (zeron n) * base (ZnZ.digits (dom_op n)) + ZnZ.to_Z x =
              ZnZ.to_Z x)%%Z).
  clear; intros; rewrite spec_zeron; auto.
 rewrite <- (@DoubleBase.spec_extend _
              (WW (zeron n)) (ZnZ.digits (dom_op n)) ZnZ.to_Z H m x).
 simpl. rewrite digits_nmake, <- nmake_double. auto.
 Qed.

 (** A particular case of extend, used in [same_level]:
     [extend_size] is [extend Size] *)

 Definition extend_size := DoubleBase.extend (WW (W0:dom_t Size)).

 Lemma spec_extend_size : forall n x, [mk_t Size x] = [Nn n (extend_size n x)].
 Proof.
 intros. rewrite spec_eval_size. apply (spec_extend Size n).
 Qed.

 (** Misc results about extensions *)

 Let spec_extend_WW : forall n x,
  [Nn (S n) (WW W0 x)] = [Nn n x].
 Proof.
 intros n x.
 set (N:=SizePlus (S n)).
 change ([Nn (S n) (extend N 0 x)]=[mk_t N x]).
 rewrite (spec_extend N 0).
 solve_eval.
 Qed.

 Let spec_extend_tr: forall m n w,
 [Nn (m + n) (extend_tr w m)] = [Nn n w].
 Proof.
 induction m; auto.
 intros n x; simpl extend_tr.
 simpl plus; rewrite spec_extend_WW; auto.
 Qed.

 Let spec_cast_l: forall n m x1,
 [Nn n x1] =
 [Nn (Max.max n m) (castm (diff_r n m) (extend_tr x1 (snd (diff n m))))].
 Proof.
 intros n m x1; case (diff_r n m); simpl castm.
 rewrite spec_extend_tr; auto.
 Qed.

 Let spec_cast_r: forall n m x1,
 [Nn m x1] =
 [Nn (Max.max n m) (castm (diff_l n m) (extend_tr x1 (fst (diff n m))))].
 Proof.
 intros n m x1; case (diff_l n m); simpl castm.
 rewrite spec_extend_tr; auto.
 Qed.

 Ltac unfold_lets :=
  match goal with
   | h : _ |- _ => unfold h; clear h; unfold_lets
   | _ => idtac
  end.

 (** * [same_level]

     Generic binary operator construction, by extending the smaller
     argument to the level of the other.
 *)

 Section SameLevel.

  Variable res: Type.
  Variable P : Z -> Z -> res -> Prop.
  Variable f : forall n, dom_t n -> dom_t n -> res.
  Variable Pf : forall n x y, P (ZnZ.to_Z x) (ZnZ.to_Z y) (f n x y).
";

for i = 0 to size do
pr "  Let f%i : w%i -> w%i -> res := f %i." i i i i
done;
pr
"  Let fn n := f (SizePlus (S n)).

  Let Pf' :
   forall n x y u v, u = [mk_t n x] -> v = [mk_t n y] -> P u v (f n x y).
  Proof.
  intros. subst. rewrite 2 spec_mk_t. apply Pf.
  Qed.
";

let ext i j s =
  if j <= i then s else Printf.sprintf "(extend %i %i %s)" i (j-i-1) s
in

pr "  Notation same_level_folded := (fun x y => match x, y with";
for i = 0 to size do
  for j = 0 to size do
    pr "  | N%i wx, N%i wy => f%i %s %s" i j (max i j) (ext i j "wx") (ext j i "wy")
  done;
  pr "  | N%i wx, Nn m wy => fn m (extend_size m %s) wy" i (ext i size "wx")
done;
for i = 0 to size do
  pr "  | Nn n wx, N%i wy => fn n wx (extend_size n %s)" i (ext i size "wy")
done;
pr
"  | Nn n wx, Nn m wy =>
    let mn := Max.max n m in
    let d := diff n m in
     fn mn
       (castm (diff_r n m) (extend_tr wx (snd d)))
       (castm (diff_l n m) (extend_tr wy (fst d)))
  end).
";

pr
"  Definition same_level := Eval lazy beta iota delta
   [ DoubleBase.extend DoubleBase.extend_aux extend zeron ]
  in same_level_folded.

  Lemma spec_same_level_0: forall x y, P [x] [y] (same_level x y).
  Proof.
  change same_level with same_level_folded. unfold_lets.
  destruct x, y; apply Pf'; simpl mk_t; rewrite <- ?spec_extend_size;
  match goal with
   | |- context [ extend ?n ?m _ ] => apply (spec_extend n m)
   | |- context [ castm _ _ ] => apply spec_cast_l || apply spec_cast_r
   | _ => reflexivity
  end.
  Qed.

 End SameLevel.

 Arguments same_level [res] f x y.

 Theorem spec_same_level_dep :
  forall res
   (P : nat -> Z -> Z -> res -> Prop)
   (Pantimon : forall n m z z' r, n <= m -> P m z z' r -> P n z z' r)
   (f : forall n, dom_t n -> dom_t n -> res)
   (Pf: forall n x y, P n (ZnZ.to_Z x) (ZnZ.to_Z y) (f n x y)),
   forall x y, P (level x) [x] [y] (same_level f x y).
 Proof.
 intros res P Pantimon f Pf.
 set (f' := fun n x y => (n, f n x y)).
 set (P' := fun z z' r => P (fst r) z z' (snd r)).
 assert (FST : forall x y, level x <= fst (same_level f' x y))
  by (destruct x, y; simpl; omega with * ).
 assert (SND : forall x y, same_level f x y = snd (same_level f' x y))
  by (destruct x, y; reflexivity).
 intros. eapply Pantimon; [eapply FST|].
 rewrite SND. eapply (@spec_same_level_0 _ P' f'); eauto.
 Qed.

 (** * [iter]

     Generic binary operator construction, by splitting the larger
     argument in blocks and applying the smaller argument to them.
 *)

 Section Iter.

  Variable res: Type.
  Variable P: Z -> Z -> res -> Prop.

  Variable f : forall n, dom_t n -> dom_t n -> res.
  Variable Pf : forall n x y, P (ZnZ.to_Z x) (ZnZ.to_Z y) (f n x y).

  Variable fd : forall n m, dom_t n -> word (dom_t n) (S m) -> res.
  Variable fg : forall n m, word (dom_t n) (S m) -> dom_t n -> res.
  Variable Pfd : forall n m x y, P (ZnZ.to_Z x) (eval n (S m) y) (fd n m x y).
  Variable Pfg : forall n m x y, P (eval n (S m) x) (ZnZ.to_Z y) (fg n m x y).

  Variable fnm: forall n m, word (dom_t Size) (S n) -> word (dom_t Size) (S m) -> res.
  Variable Pfnm: forall n m x y, P [Nn n x] [Nn m y] (fnm n m x y).

  Let Pf' :
   forall n x y u v, u = [mk_t n x] -> v = [mk_t n y] -> P u v (f n x y).
  Proof.
  intros. subst. rewrite 2 spec_mk_t. apply Pf.
  Qed.

  Let Pfd' : forall n m x y u v, u = [mk_t n x] -> v = eval n (S m) y ->
   P u v (fd n m x y).
  Proof.
  intros. subst. rewrite spec_mk_t. apply Pfd.
  Qed.

  Let Pfg' : forall n m x y u v, u = eval n (S m) x -> v = [mk_t n y] ->
   P u v (fg n m x y).
  Proof.
  intros. subst. rewrite spec_mk_t. apply Pfg.
  Qed.
";

for i = 0 to size do
pr "  Let f%i := f %i." i i
done;

for i = 0 to size do
pr "  Let f%in := fd %i." i i;
pr "  Let fn%i := fg %i." i i;
done;

pr "  Notation iter_folded := (fun x y => match x, y with";
for i = 0 to size do
  for j = 0 to size do
    pr "  | N%i wx, N%i wy => f%s wx wy" i j
      (if i = j then string_of_int i
       else if i < j then string_of_int i ^ "n " ^ string_of_int (j-i-1)
       else "n" ^ string_of_int j ^ " " ^ string_of_int (i-j-1))
  done;
  pr "  | N%i wx, Nn m wy => f%in m %s wy" i size (ext i size "wx")
done;
for i = 0 to size do
  pr "  | Nn n wx, N%i wy => fn%i n wx %s" i size (ext i size "wy")
done;
pr
"  | Nn n wx, Nn m wy => fnm n m wx wy
  end).
";

pr
"  Definition iter := Eval lazy beta iota delta
   [extend DoubleBase.extend DoubleBase.extend_aux zeron]
   in iter_folded.

  Lemma spec_iter: forall x y, P [x] [y] (iter x y).
  Proof.
  change iter with iter_folded; unfold_lets.
  destruct x; destruct y; apply Pf' || apply Pfd' || apply Pfg' || apply Pfnm;
  simpl mk_t;
  match goal with
   | |- ?x = ?x => reflexivity
   | |- [Nn _ _] = _ => apply spec_eval_size
   | |- context [extend ?n ?m _] => apply (spec_extend n m)
   | _ => idtac
  end;
  unfold to_Z; rewrite <- spec_plus_t'; simpl dom_op; reflexivity.
  Qed.

  End Iter.
";

pr
"  Definition switch
  (P:nat->Type)%s
  (fn:forall n, P n) n :=
  match n return P n with"
  (iter_str_gen size (fun i -> Printf.sprintf "(f%i:P %i)" i i));
for i = 0 to size do pr "   | %i => f%i" i i done;
pr
"   | n => fn n
  end.
";

pr
"  Lemma spec_switch : forall P (f:forall n, P n) n,
   switch P %sf n = f n.
  Proof.
  repeat (destruct n; try reflexivity).
  Qed.
" (iter_str_gen size (fun i -> Printf.sprintf "(f %i) " i));

pr
"  (** * [iter_sym]

    A variant of [iter] for symmetric functions, or pseudo-symmetric
    functions (when f y x can be deduced from f x y).
  *)

  Section IterSym.

  Variable res: Type.
  Variable P: Z -> Z -> res -> Prop.

  Variable f : forall n, dom_t n -> dom_t n -> res.
  Variable Pf : forall n x y, P (ZnZ.to_Z x) (ZnZ.to_Z y) (f n x y).

  Variable fg : forall n m, word (dom_t n) (S m) -> dom_t n -> res.
  Variable Pfg : forall n m x y, P (eval n (S m) x) (ZnZ.to_Z y) (fg n m x y).

  Variable fnm: forall n m, word (dom_t Size) (S n) -> word (dom_t Size) (S m) -> res.
  Variable Pfnm: forall n m x y, P [Nn n x] [Nn m y] (fnm n m x y).

  Variable opp: res -> res.
  Variable Popp : forall u v r, P u v r -> P v u (opp r).
";

for i = 0 to size do
pr "  Let f%i := f %i." i i
done;

for i = 0 to size do
pr "  Let fn%i := fg %i." i i;
done;

pr "  Let f' := switch _ %s f." (iter_name 0 size "f" "");
pr "  Let fg' := switch _ %s fg." (iter_name 0 size "fn" "");

pr
"  Local Notation iter_sym_folded :=
   (iter res f' (fun n m x y => opp (fg' n m y x)) fg' fnm).

  Definition iter_sym :=
   Eval lazy beta zeta iota delta [iter f' fg' switch] in iter_sym_folded.

  Lemma spec_iter_sym: forall x y, P [x] [y] (iter_sym x y).
  Proof.
  intros. change iter_sym with iter_sym_folded. apply spec_iter; clear x y.
  unfold_lets.
  intros. rewrite spec_switch. auto.
  intros. apply Popp. unfold_lets. rewrite spec_switch; auto.
  intros. unfold_lets. rewrite spec_switch; auto.
  auto.
  Qed.

  End IterSym.

 (** * Reduction

     [reduce] can be used instead of [mk_t], it will choose the
     lowest possible level. NB: We only search and remove leftmost
     W0's via ZnZ.eq0, any non-W0 block ends the process, even
     if its value is 0.
 *)

 (** First, a direct version ... *)

 Fixpoint red_t n : dom_t n -> t :=
  match n return dom_t n -> t with
   | O => N0
   | S n => fun x =>
     let x' := pred_t n x in
     reduce_n1 _ _ (N0 zero0) ZnZ.eq0 (red_t n) (mk_t_S n) x'
  end.

 Lemma spec_red_t : forall n x, [red_t n x] = [mk_t n x].
 Proof.
 induction n.
 reflexivity.
 intros.
 simpl red_t. unfold reduce_n1.
 rewrite <- (succ_pred_t n x) at 2.
 remember (pred_t n x) as x'.
 rewrite spec_mk_t, spec_succ_t.
 destruct x' as [ | xh xl]. simpl. apply ZnZ.spec_0.
 generalize (ZnZ.spec_eq0 xh); case ZnZ.eq0; intros H.
 rewrite IHn, spec_mk_t. simpl. rewrite H; auto.
 apply spec_mk_t_S.
 Qed.

 (** ... then a specialized one *)
";

for i = 0 to size do
pr " Definition eq0%i := @ZnZ.eq0 _ w%i_op." i i;
done;

pr "
 Definition reduce_0 := N0.";
for i = 1 to size do
  pr " Definition reduce_%i :=" i;
  pr "  Eval lazy beta iota delta [reduce_n1] in";
  pr "   reduce_n1 _ _ (N0 zero0) eq0%i reduce_%i N%i." (i-1) (i-1) i
done;

  pr " Definition reduce_%i :=" (size+1);
  pr "  Eval lazy beta iota delta [reduce_n1] in";
  pr "   reduce_n1 _ _ (N0 zero0) eq0%i reduce_%i (Nn 0)." size size;

  pr " Definition reduce_n n :=";
  pr "  Eval lazy beta iota delta [reduce_n] in";
  pr "   reduce_n _ _ (N0 zero0) reduce_%i Nn n." (size + 1);
  pr "";

pr " Definition reduce n : dom_t n -> t :=";
pr "  match n with";
for i = 0 to size do
pr "   | %i => reduce_%i" i i;
done;
pr "   | %s(S n) => reduce_n n" (if size=0 then "" else "SizePlus ");
pr "  end.";
pr "";

pr " Ltac unfold_red := unfold reduce, %s." (iter_name 1 size "reduce_" ",");
pr "";
for i = 0 to size do
pr " Declare Equivalent Keys reduce reduce_%i." i;
done;
pr " Declare Equivalent Keys reduce_n reduce_%i." (size + 1);

pr "
 Ltac solve_red :=
 let H := fresh in let G := fresh in
 match goal with
  | |- ?P (S ?n) => assert (H:P n) by solve_red
  | _ => idtac
 end;
 intros n G x; destruct (le_lt_eq_dec _ _ G) as [LT|EQ];
 solve [
  apply (H _ (lt_n_Sm_le _ _ LT)) |
  inversion LT |
  subst; change (reduce 0 x = red_t 0 x); reflexivity |
  specialize (H (pred n)); subst; destruct x;
   [|unfold_red; rewrite H; auto]; reflexivity
 ].

 Lemma reduce_equiv : forall n x, n <= Size -> reduce n x = red_t n x.
 Proof.
 set (P N := forall n, n <= N -> forall x, reduce n x = red_t n x).
 intros n x H. revert n H x. change (P Size). solve_red.
 Qed.

 Lemma spec_reduce_n : forall n x, [reduce_n n x] = [Nn n x].
 Proof.
 assert (H : forall x, reduce_%i x = red_t (SizePlus 1) x).
  destruct x; [|unfold reduce_%i; rewrite (reduce_equiv Size)]; auto.
 induction n.
   intros. rewrite H. apply spec_red_t.
 destruct x as [|xh xl].
 simpl. rewrite make_op_S. exact ZnZ.spec_0.
 fold word in *.
 destruct xh; auto.
 simpl reduce_n.
 rewrite IHn.
 rewrite spec_extend_WW; auto.
 Qed.
" (size+1) (size+1);

pr
" Lemma spec_reduce : forall n x, [reduce n x] = ZnZ.to_Z x.
 Proof.
 do_size (destruct n;
       [intros; rewrite reduce_equiv;[apply spec_red_t|auto with arith]|]).
 apply spec_reduce_n.
 Qed.

End Make.
";
