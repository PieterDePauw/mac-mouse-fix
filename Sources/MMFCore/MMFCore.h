//
// --------------------------------------------------------------------------
// MMFCore.h
// Created for Mac Mouse Fix (https://github.com/noah-nuebling/mac-mouse-fix)
// Licensed under the MMF License (https://github.com/noah-nuebling/mac-mouse-fix/blob/master/License)
// --------------------------------------------------------------------------
//

/// Umbrella header of the MMFCore static framework. [Oct 2026]
///     MMFCore holds the leaf modules of Shared that have no per-target (`IS_HELPER` / `IS_MAIN_APP`) code.
///     It is linked statically into the App and the Helper.
///     Only headers that MMFCore's own Swift code (or the apps' Swift code via `import MMFCore`) needs belong here. ObjC code keeps finding the other headers through the header map.

#import <Foundation/Foundation.h>

#import <MMFCore/SharedMacros.h>
#import <MMFCore/Logging.h>
#import <MMFCore/Constants.h>
#import <MMFCore/Shorthands.h>
#import <MMFCore/VectorUtility.h>
#import <MMFCore/MathObjc.h>
#import <MMFCore/AnimatorDeclarations.h>
#import <MMFCore/PolynomialRegression.h>
#import <MMFCore/MFCoding.h>
