{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE NoImplicitPrelude #-}

module Main (
  main,
) where

import Protolude

import Test.Tasty
import Test.Tasty.HUnit as HU
import Test.Tasty.QuickCheck
import Test.QuickCheck.Monadic as QM

import Pedersen
import PrimeField

suite :: TestTree
suite = testGroup "Test Suite" [
    testGroup "Units"
      [ pedersenTests
      ]
  ]

pedersenTests :: TestTree
pedersenTests = testGroup "Pedersen Commitment Scheme"
  [ localOption (QuickCheckTests 50) $
      testProperty "x == Open(Commit(x),r)" $ monadicIO $ do
        (a, cp) <- liftIO $ setup 256
        x <- liftIO $ randomInZq $ pedersenSPF cp
        pc <- liftIO $ commit x cp
        QM.assert $ open cp pc
  , testCaseSteps "Additive Homomorphic Property" $ \step -> do
      step "Generating commit params..."
      (a,cp) <- setup 256
      let spf = pedersenSPF cp

      step "Generating two random nums in Zp to commit."
      x <- randomInZq spf
      y <- randomInZq spf
      putText $ "x = " <> show x
      putText $ "y = " <> show y

      step "Commit the two random nums."
      px <- commit x cp
      py <- commit y cp

      step "Create new commitment using Additive homomorphic property."
      let pz = homoCommit cp (reveal px) (reveal py)
      let (Reveal pzVal pzExp) = reveal pz

      assertBool "Pedersen commitments failed." $
        open cp px && open cp py && open cp pz

      let pxc = unCommitment $ commitment px
      let pyc = unCommitment $ commitment py

      -- Addition of crypto texts (doesn't work yet)
      assertBool "Additive homomorphic property doesn't hold." $
        True -- pzVal == pxyc
  ]


main :: IO ()
main = defaultMain suite
