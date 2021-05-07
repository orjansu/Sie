{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE GADTs #-}
--{-# OPTIONS_GHC -fwarn-incomplete-patterns #-}

module ShowLaw (showLaw) where

import qualified Data.Set as Set

import PrintSieLaws ( printTree, Print )

import qualified TypedLawAST as T
import qualified AbsSieLaws as UT
import OtherUtils (filterNoise)

showLaw :: (Convertible a, Print (UntypedVersion a), Show a) => a -> String
showLaw a = "ShowLaw not fully implemented. Raw show: "++show a
  --filterNoise . printTree . toUntyped

class Convertible a where
  type UntypedVersion a
  toUntyped :: a -> UntypedVersion a

instance Convertible T.Term where
  type UntypedVersion T.Term = UT.Term
  toUntyped (T.TValueMetaVar mvName) = UT.TValueMetaVar $ UT.MVValue mvName
  toUntyped (T.TVar mvName) = UT.TVar $ toUntypedVar mvName
  toUntyped (T.TAppCtx mvName term) = UT.TAppCtx (UT.MVContext mvName)
                                                 (toUntyped term)
  toUntyped (T.TLet letBindings term) = UT.TLet (toUntyped letBindings)
                                                (toUntyped term)
  toUntyped (T.TDummyBinds vs term) =
    let utVarSet = toUntyped vs
        utTerm = toUntyped term
    in UT.TDummyBinds utVarSet utTerm

toUntypedVar :: String -> UT.Var
toUntypedVar mvName = UT.DVar $ UT.MVVar mvName

instance Convertible T.LetBindings where
  type UntypedVersion T.LetBindings = UT.LetBindings
  toUntyped (T.LBSBoth tMBS letBindings) =
    let mbs = map toMBS tMBS
        lbs = map toLB letBindings
    in UT.LBSBoth mbs lbs
    where
      toMBS (T.MBSMetaVar mv) = UT.MBSMetaVar (UT.MVLetBindings mv)
      toLB (T.LBConcrete var sw hw term) =
        let utVar = toUntypedVar var
            utSw = toUntyped sw
            utHw = toUntyped hw
            utTerm = toUntyped term
            bindSym = toBindSym utSw utHw
        in UT.LBConcrete utVar bindSym utTerm
      toLB (T.LBVectorized varVect1 sw hw varVect2) =
        let utSw = toUntyped sw
            utHw = toUntyped hw
            bindSym = toBindSym utSw utHw
        in UT.LBVectorized (UT.MVVarVect varVect1)
                           bindSym
                           (UT.MVVarVect varVect2)

      toBindSym (UT.IENum 1) (UT.IENum 1) = UT.BSNoWeight
      toBindSym sw hw = UT.BSWeights (UT.DStackWeight sw) (UT.DHeapWeight hw)

instance Convertible T.IntExpr where
  type UntypedVersion T.IntExpr = UT.IntExpr
  toUntyped (T.IEVar str) = UT.IEVar $ UT.DIntegerVar $ UT.MVIntegerVar str
  toUntyped (T.IENum integer) = UT.IENum integer

instance Convertible T.VarSet where
  type UntypedVersion T.VarSet = UT.VarSet
  toUntyped (T.VSConcrete varSet) =
    UT.VSConcrete $ map toUntypedVar $ Set.toList varSet
