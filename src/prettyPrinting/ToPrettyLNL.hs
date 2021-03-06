{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE FlexibleInstances #-}
{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}

module ToPrettyLNL (showLNL, Convertible, PrintVersion) where

import qualified Data.Set as Set

import qualified LocallyNameless as LNL
import qualified AbsLNL as P
import PrintLNL (printTree, Print)
import OtherUtils (filterNoise)

showLNL :: (Convertible a, Print (PrintVersion a)) => a -> String
showLNL = filterNoise . printTree . toPrintable

class Convertible a where
  type PrintVersion a
  toPrintable :: a -> PrintVersion a

instance Convertible LNL.Term where
  type PrintVersion LNL.Term = P.Term
  toPrintable (LNL.TNonTerminating) = P.TNonTerminating
  toPrintable (LNL.TVar var) = P.TVar (toPrintable var)
  toPrintable (LNL.TNum int) = P.TNum int
  toPrintable (LNL.TConstructor name args) =
    let pArgs = map toPrintable args
        pName = P.Ident name
    in P.TConstructor pName pArgs
  toPrintable (LNL.THole) = P.THole
  toPrintable (LNL.TLam term) = P.TLam (toPrintable term)
  toPrintable (LNL.TLet letBindings term) = P.TLet (convertLbs letBindings)
                                                   (toPrintable term)
    where
      convertLbs = map toPrintable
  toPrintable (LNL.TDummyBinds varSet term) = P.TDummyBinds (convertVS varSet)
                                                            (toPrintable term)
    where
      convertVS = (map toPrintable) . Set.toAscList
  toPrintable (LNL.TStackSpikes sw term) =
    let pTerm = toPrintable term
    in P.TStackSpikes sw pTerm
  toPrintable (LNL.THeapSpikes hw term) =
    let pTerm = toPrintable term
    in P.THeapSpikes hw pTerm
  toPrintable (LNL.TRedWeight 1 red) = P.TRed (toPrintable red)
  toPrintable (LNL.TRedWeight 0 (LNL.RApp term var)) =
    P.TRAppNoW (toPrintable term) (toPrintable var)
  toPrintable (LNL.TRedWeight redWeight red) = P.TRedWeight redWeight
                                                            (toPrintable red)

instance Convertible (Integer, Integer, LNL.Term) where
  type PrintVersion (Integer, Integer, LNL.Term) = P.LetBinding
  toPrintable (1, 1,term) = P.LBNoWeight (toPrintable term)
  toPrintable (sw, hw, term) = P.LBWeight sw hw (toPrintable term)

instance Convertible LNL.Red where
  type PrintVersion LNL.Red = P.Red
  toPrintable (LNL.RApp term var) = P.RApp (toPrintable term) (toPrintable var)
  toPrintable (LNL.RCase term cases) =
    let pTerm = toPrintable term
        pCases = map toPCase cases
    in P.RCase pTerm pCases
    where
      toPCase (name, term) = let pTerm = toPrintable term
                                 pName = P.Ident name
                             in P.DCaseStm pName pTerm
  toPrintable (LNL.RPlusWeight term1 1 term2) =
    P.RPlus (toPrintable term1) (toPrintable term2)
  toPrintable (LNL.RPlusWeight term1 rw term2) =
    P.RPlusWeight (toPrintable term1) rw (toPrintable term2)
  toPrintable (LNL.RAddConst int term) =
    let pTerm = toPrintable term
    in P.RAddConst int pTerm
  toPrintable (LNL.RIsZero term) = P.RIsZero (toPrintable term)
  toPrintable (LNL.RSeq t1 t2) = P.RSeq (toPrintable t1) (toPrintable t2)

instance Convertible LNL.Var where
  type PrintVersion LNL.Var = P.Var
  toPrintable (LNL.LambdaVar i) = P.LambdaVar i
  toPrintable (LNL.LetVar i1 i2) = P.LetVar i1 i2
  toPrintable (LNL.CaseConstructorVar i1 i2) = P.CaseConstructorVar i1 i2
  toPrintable (LNL.FreeVar name) = P.FreeVar name
