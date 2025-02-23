/*
 * Copyright 2021 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface GACAppAttestStoredArtifact : NSObject <NSSecureCoding>

/// The App Attest key ID used to generate the artifact.
@property(nonatomic, readonly) NSString *keyID;

/// The Firebase App Attest artifact generated by the backend.
@property(nonatomic, readonly) NSData *artifact;

/// The object version.
/// WARNING: The version must be incremented if properties are added, removed or modified. Migration
/// must be handled accordingly in `initWithCoder:` method.
@property(nonatomic, readonly) NSInteger storageVersion;

- (instancetype)init NS_UNAVAILABLE;

- (instancetype)initWithKeyID:(NSString *)keyID
                     artifact:(NSData *)artifact NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
