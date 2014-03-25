/*!
 @file NuRSAKey.m
 @copyright Copyright (c) 2011 Radtastical, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "NuRSAKey.h"
#import "NuBinaryEncoding.h"

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "openssl/err.h"
#include "openssl/ssl.h"

@implementation NuRSAKey

- (id) init
{
    if (self = [super init]) {
        key = RSA_generate_key(1024, RSA_F4, NULL, NULL);
    }
    return self;
}

- (id) initWithModulus:(NSString *) modulus exponent:(NSString *) exponent
{
    if (self = [super init]) {
        key = RSA_new();
        if (modulus) {
            BN_hex2bn(&(key->n), [modulus cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        if (exponent) {
            BN_hex2bn(&(key->e), [exponent cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
    return self;
}

- (id) initWithModulusData:(NSData *) modulus exponentData:(NSData *) exponent
{
    if (self = [super init]) {
        key = RSA_new();
        if (modulus) {
            key->n = BN_bin2bn([modulus bytes], [modulus length], NULL);
        }
        if (exponent) {
			key->e = BN_bin2bn([exponent bytes], [exponent length], NULL);
        }
    }
    return self;
}

- (id) initWithPEMPrivateKeyData:(NSData *) data {
	if (self = [super init]) {
		BIO *b = BIO_new(BIO_s_mem());
		BIO_write(b, [data bytes], [data length]);
		key = PEM_read_bio_RSAPrivateKey(b, &key, NULL, NULL);
		if (!key) {

			return nil;
		}
	}
	return self;
}

- (id) initWithDERPublicKeyData:(NSData *) data {
	if (self = [super init]) {
		const unsigned char *buffer, *next;
		next = buffer = (const unsigned char *) [data bytes];
		key = d2i_RSAPublicKey(NULL, &next, [data length]);		
	}
	return self;
}

- (NSData *) DERPublicKeyData {
	unsigned char *buffer, *next;
	int length = i2d_RSAPublicKey(key, NULL);
	next = buffer = (unsigned char *) malloc (length);			
	i2d_RSAPublicKey(key, &next);	
	return [NSData dataWithBytes:buffer length:length];
}


static NSString *string_for_object(id object)
{
    if ([object isKindOfClass:[NSData class]]) {
        NSString *string = [object hexEncodedString];
        return string;
    }
    else if ([object isKindOfClass:[NSString class]]) {
        return object;
    }
    else {
        return nil;
    }
}

- (id) initWithDictionary:(NSDictionary *) dictionary
{
    if (self = [super init]) {
        key = RSA_new();
        id n,e,d,p,q;
        if ((n = [dictionary objectForKey:@"n"])) {
            n = string_for_object(n);
            BN_hex2bn(&(key->n), [n cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        if ((e = [dictionary objectForKey:@"e"])) {
            e = string_for_object(e);
            BN_hex2bn(&(key->e), [e cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        if ((d = [dictionary objectForKey:@"d"])) {
            d = string_for_object(d);
            BN_hex2bn(&(key->d), [d cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        if ((p = [dictionary objectForKey:@"p"])) {
            p = string_for_object(p);
            BN_hex2bn(&(key->p), [p cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        if ((q = [dictionary objectForKey:@"q"])) {
            q = string_for_object(q);
            BN_hex2bn(&(key->q), [q cStringUsingEncoding:NSUTF8StringEncoding]);
        }
    }
    return self;
}

- (int) maxSize
{
    return RSA_size(key);
}

- (int) check
{
	return RSA_check_key(key);
}

- (NSString *) modulus
{
    return [NSString stringWithCString:BN_bn2hex(key->n) encoding:NSUTF8StringEncoding];
}

- (NSString *) exponent
{
    return [NSString stringWithCString:BN_bn2hex(key->e) encoding:NSUTF8StringEncoding];
}

static NSData *data(NSString *string)
{
    return [NSData dataWithHexEncodedString:string];
}

- (NSDictionary *) dictionaryRepresentation
{
    NSMutableDictionary *representation = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                           data([NSString stringWithCString:BN_bn2hex(key->n) encoding:NSUTF8StringEncoding]), @"n",
                                           data([NSString stringWithCString:BN_bn2hex(key->e) encoding:NSUTF8StringEncoding]), @"e",
                                           nil];
    if (key->d) {
        [representation setObject:data([NSString stringWithCString:BN_bn2hex(key->d) encoding:NSUTF8StringEncoding])
                           forKey:@"d"];
    }
    if (key->p) {
        [representation setObject:data([NSString stringWithCString:BN_bn2hex(key->p) encoding:NSUTF8StringEncoding])
                           forKey:@"p"];
    }
    if (key->q) {
        [representation setObject:data([NSString stringWithCString:BN_bn2hex(key->q) encoding:NSUTF8StringEncoding])
                           forKey:@"q"];
    }
    return representation;
}

- (NSDictionary *) publicKeyDictionaryRepresentation
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
            data([NSString stringWithCString:BN_bn2hex(key->n) encoding:NSUTF8StringEncoding]), @"n",
            data([NSString stringWithCString:BN_bn2hex(key->e) encoding:NSUTF8StringEncoding]), @"e",
            nil];
}

- (NSData *) encryptDataWithPublicKey:(NSData *) data
{
    int maxSize = RSA_size(key);
    unsigned char *output = (unsigned char *) malloc(maxSize * sizeof(char));
    int bytes = RSA_public_encrypt([data length], [data bytes], output, key, RSA_PKCS1_PADDING);
	return (bytes > 0) ? [NSData dataWithBytes:output length:bytes] : nil;
}

- (NSData *) encryptDataWithPrivateKey:(NSData *) data
{
    int maxSize = RSA_size(key);
    unsigned char *output = (unsigned char *) malloc(maxSize * sizeof(char));
    int bytes = RSA_private_encrypt([data length], [data bytes], output, key, RSA_PKCS1_PADDING);
    return (bytes > 0) ? [NSData dataWithBytes:output length:bytes] : nil;
}

- (NSData *) decryptDataWithPublicKey:(NSData *) data
{
    int maxSize = RSA_size(key);
    unsigned char *output = (unsigned char *) malloc(maxSize * sizeof(char));
    int bytes = RSA_public_decrypt([data length], [data bytes], output, key, RSA_PKCS1_PADDING);
    return (bytes > 0) ? [NSData dataWithBytes:output length:bytes] : nil;
}

- (NSData *) decryptDataWithPrivateKey:(NSData *) data
{
    int maxSize = RSA_size(key);
    unsigned char *output = (unsigned char *) malloc(maxSize * sizeof(char));
    int bytes = RSA_private_decrypt([data length], [data bytes], output, key, RSA_PKCS1_PADDING);
	return (bytes > 0) ? [NSData dataWithBytes:output length:bytes] : nil;
}

- (NSData *)stripPublicKeyHeader:(NSData *)d_key
{
    // Skip ASN.1 public key header
    if (d_key == nil) return(nil);
    
    unsigned int len = [d_key length];
    if (!len) return(nil);
    
    unsigned char *c_key = (unsigned char *)[d_key bytes];
    unsigned int  idx    = 0;
    
    if (c_key[idx++] != 0x30) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    // PKCS #1 rsaEncryption szOID_RSA_RSA
    static unsigned char seqiod[] =
    { 0x30,   0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01,
        0x01, 0x05, 0x00 };
    if (memcmp(&c_key[idx], seqiod, 15)) return(nil);
    
    idx += 15;
    
    if (c_key[idx++] != 0x03) return(nil);
    
    if (c_key[idx] > 0x80) idx += c_key[idx] - 0x80 + 1;
    else idx++;
    
    if (c_key[idx++] != '\0') return(nil);
    
    // Now make a new NSData from this buffer
    return([NSData dataWithBytes:&c_key[idx] length:len - idx]);
}


@end
