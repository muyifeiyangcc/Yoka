//
//  YKOutfitFeedCatalog.m
//  Yoka
//

#import "YKOutfitFeedCatalog.h"
#import "YKPersonaCatalog.h"

@implementation YKOutfitFeedCatalog

+ (NSArray<NSString *> *)yk_remarkerIdsExcludingPublisher:(NSString *)publisherId {
    NSMutableArray<NSString *> *ids = [NSMutableArray array];
    for (NSDictionary *persona in [YKPersonaCatalog yk_allPersonas]) {
        NSString *personaId = persona[@"id"];
        if (![personaId isEqualToString:publisherId]) {
            [ids addObject:personaId];
        }
    }
    return ids;
}

+ (NSArray<NSDictionary *> *)yk_remarksWithTexts:(NSArray<NSString *> *)texts publisherId:(NSString *)publisherId {
    NSArray<NSString *> *pool = [self yk_remarkerIdsExcludingPublisher:publisherId];
    NSUInteger start = publisherId.hash % MAX(pool.count, 1);
    NSMutableArray<NSDictionary *> *comments = [NSMutableArray arrayWithCapacity:texts.count];
    for (NSInteger index = 0; index < (NSInteger)texts.count; index++) {
        NSString *commenterId = pool[(start + (NSUInteger)index) % pool.count];
        NSDictionary *persona = [YKPersonaCatalog yk_personaWithId:commenterId];
        [comments addObject:@{
            @"personaId": commenterId ?: @"",
            @"name": persona[@"name"] ?: @"Yoka",
            @"text": texts[index]
        }];
    }
    return comments;
}

+ (NSArray<NSDictionary *> *)yk_outfitPosts {
    static NSArray<NSDictionary *> *posts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        posts = @[
            @{
                @"personaId": @"korae",
                @"name": @"Korae",
                @"caption": @"Cyber millennial fit. Metallic accents, reflective details and nostalgic 00s silhouettes.",
                @"video": @"uniserolyoka00",
                @"ratio": @1.38,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"This Y2K fit is unreal, so stunning!",
                    @"You pull off early 00s fashion perfectly.",
                    @"Every detail of this outfit matches the aesthetic so well.",
                    @"Looks straight out of a 2000s magazine."
                ] publisherId:@"korae"],
                @"items": @[
                    @{
                        @"image": @"product_item_01",
                        @"brand": @"Unbranded",
                        @"price": @"$58",
                        @"description": @"Dark brown slim tube top layered with shaggy faux fur trim and eyelet waist strap, side ruching creates a figure-hugging fit. Fur trimmed bustier tops were widely popular in early 2000s autumn Y2K outfits."
                    },
                    @{
                        @"image": @"product_item_02",
                        @"brand": @"Unbranded",
                        @"price": @"$55",
                        @"description": @"Fitted V-Neck Short Sleeve T-Shirt With Light Blue Ink Floral Print And Cursive Letter Details. Side waist ruched design creates a curved cropped hem. Slim silhouette and soft watercolor flower graphics are classic soft Y2K casual tops, easy to match low-rise jeans and mini skirts."
                    },
                    @{
                        @"image": @"product_item_03",
                        @"brand": @"Unbranded",
                        @"price": @"$59",
                        @"description": @"Sleeveless fitted tank top decorated with soft watercolor pink lily floral print, layered side ruched detailing to shape the waist. Slim silhouette and dreamy pastel flower graphics are classic soft Y2K summer essential, perfectly matched with low-rise denim bottoms and mini skirts."
                    },
                    @{
                        @"image": @"product_item_04",
                        @"brand": @"Unbranded",
                        @"price": @"$72",
                        @"description": @"Cute platform canvas sneakers decorated with detachable pink star appliqué, two-tone white and pastel pink matching. Thick rounded toe sole and vintage wooden tag details deliver sweet millennial energy. The star ornament and chunky silhouette are iconic Y2K footwear, matching all kinds of low-rise pants and mini skirts."
                    }
                ]
            },
            @{
                @"personaId": @"orbelle",
                @"name": @"Orbelle",
                @"caption": @"Flip Phone Era Fashion Never Goes Out Of Style.",
                @"image": @"foryou_yuvette",
                @"ratio": @1.18,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"This y2k fit is absolutely iconic",
                    @"You were born to rock early 2000s style",
                    @"Every detail of this look is flawless"
                ] publisherId:@"orbelle"],
                @"items": @[
                    @{
                        @"image": @"product_item_05",
                        @"brand": @"Unbranded",
                        @"price": @"$69",
                        @"description": @"Vintage washed graphic tee featuring faded monochrome character print and retro date text. Faded band-style portrait prints and relaxed silhouette are classic 2000s streetwear, fits dark Y2K and retro millennial styling."
                    }
                ]
            },
            @{
                @"personaId": @"ellex",
                @"name": @"Ellex",
                @"caption": @"Classic Y2K OOTD Inspired By Early 2000s Trends.",
                @"image": @"foryou_zely",
                @"ratio": @1.28,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"This Y2K Fit Is Absolutely Iconic.",
                    @"The Overall Vibe Is Immaculate."
                ] publisherId:@"ellex"]
            },
            @{
                @"personaId": @"zely",
                @"name": @"Zely",
                @"caption": @"Mixing glitter, denim and soft fabrics. The perfect Y2K combination.",
                @"image": @"style_cover_8p",
                @"ratio": @1.32,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"I Am Instantly Transported Back To The Early 00s.",
                    @"Such Effortless Millennial Charm."
                ] publisherId:@"zely"],
                @"items": @[
                    @{
                        @"image": @"product_item_06",
                        @"brand": @"Unbranded",
                        @"price": @"$76",
                        @"description": @"Asymmetrical plaid micro mini pleated skirt, matched with wide buckle belt and metal eyelet decoration. Raw frayed hem adds punk texture. Ultra-low waist micro skirt and plaid punk design are classic early 2000s Y2K staple for alt streetwear."
                    }
                ]
            },
            @{
                @"personaId": @"yuvette",
                @"name": @"Yuvette",
                @"caption": @"Dressed Like It’s 2003. Embracing Raw CCD Flash And Iconic Y2K Outfits.",
                @"video": @"uniserolyoka03",
                @"ratio": @1.24,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"Cool And Timeless Early 00s Streetwear.",
                    @"Such Bold And Attractive Retro-Futuristic Outfit."
                ] publisherId:@"yuvette"]
            },
            @{
                @"personaId": @"ellex",
                @"name": @"Ellex",
                @"caption": @"Permanently Stuck In A 2000s Fashion Loop.",
                @"video": @"uniserolyoka19",
                @"ratio": @1.36,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"This Look Hits Different."
                ] publisherId:@"ellex"]
            }
        ];
    });
    return posts;
}

+ (NSArray<NSDictionary *> *)yk_makeupPosts {
    static NSArray<NSDictionary *> *posts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        posts = @[
            @{
                @"personaId": @"zely",
                @"name": @"Zely",
                @"caption": @"Edgy Y2K Makeup Tutorial. Metallic Eyeshadow, Thin Eyeliner And Shiny Gloss Define This Early 2000s Look.",
                @"video": @"uniserolyoka07",
                @"ratio": @1.28,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"This Y2K Makeup Look Is So Stunning.",
                    @"The Combination Of Glitter And Gloss Looks Incredible."
                ] publisherId:@"zely"]
            },
            @{
                @"personaId": @"korae",
                @"name": @"Korae",
                @"caption": @"Mixing Metallic Shades And Glossy Lips To Achieve Authentic Cyber Y2K Glam.",
                @"video": @"uniserolyoka09",
                @"ratio": @1.22,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"The Metallic Shadows Make This Look So Eye-Catching.",
                    @"Edgy Y2K Makeup Done Absolutely Flawlessly."
                ] publisherId:@"korae"]
            },
            @{
                @"personaId": @"yuvette",
                @"name": @"Yuvette",
                @"caption": @"Flash-Friendly Y2K Makeup Perfect For CCD Portraits. The Shimmer Glows Beautifully Under Camera Flash.",
                @"image": @"trending_style_04",
                @"ratio": @1.34,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"You Truly Understand The Charm Of Y2K Beauty."
                ] publisherId:@"yuvette"]
            }
        ];
    });
    return posts;
}

+ (NSArray<NSDictionary *> *)yk_hairPosts {
    static NSArray<NSDictionary *> *posts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        posts = @[
            @{
                @"personaId": @"yuvette",
                @"name": @"Yuvette",
                @"caption": @"Channeling 2000s Street Style With This Sleek Y2K Hairstyle.",
                @"video": @"uniserolyoka13",
                @"ratio": @1.26,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"This Y2K Hairstyle Looks Absolutely Gorgeous."
                ] publisherId:@"yuvette"]
            },
            @{
                @"personaId": @"zely",
                @"name": @"Zely",
                @"caption": @"Edgy Y2K Hair Inspo. Sleek Strands, Baby Hairs And Chunky Highlights Represent Retro-Futuristic Millennial Style.",
                @"video": @"uniserolyoka22",
                @"ratio": @1.32,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"You Totally Nailed The Authentic Early 2000s Hair Aesthetic."
                ] publisherId:@"zely"]
            },
            @{
                @"personaId": @"korae",
                @"name": @"Korae",
                @"caption": @"Mixing Bold Streaks And Half-Up Style For A Unique Cyber Y2K Look.",
                @"video": @"uniserolyoka12",
                @"ratio": @1.20,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"The Texture And Volume Of This Hair Are Flawless."
                ] publisherId:@"korae"]
            }
        ];
    });
    return posts;
}

+ (NSArray<NSDictionary *> *)yk_jewelryPosts {
    static NSArray<NSDictionary *> *posts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        posts = @[
            @{
                @"personaId": @"korae",
                @"name": @"Korae",
                @"caption": @"Embracing Dreamy Early 2000s Y2K Aesthetic Filled With Nostalgia And Soft Sparkle.",
                @"video": @"uniserolyoka14",
                @"ratio": @1.24,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"This Whole Y2K Vibe Is Absolutely Immaculate."
                ] publisherId:@"korae"]
            },
            @{
                @"personaId": @"yuvette",
                @"name": @"Yuvette",
                @"caption": @"Little Sparkling Details Make The Perfect Y2K Look Full Of Personality.",
                @"video": @"uniserolyoka15",
                @"ratio": @1.30,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"You Have Perfectly Captured The True Spirit Of Y2K Aesthetic."
                ] publisherId:@"yuvette"]
            }
        ];
    });
    return posts;
}

+ (NSArray<NSDictionary *> *)yk_shoesPosts {
    static NSArray<NSDictionary *> *posts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        posts = @[
            @{
                @"personaId": @"zely",
                @"name": @"Zely",
                @"caption": @"Revisiting Legendary Shoe Styles From The 2000s. Simple Yet Eye-Catching Designs Match All Kinds Of Y2K Fits.",
                @"video": @"uniserolyoka20",
                @"ratio": @1.28,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"This Pair Of Y2K Shoes Is Absolutely Stunning."
                ] publisherId:@"zely"],
                @"items": @[
                    @{
                        @"image": @"product_item_07",
                        @"brand": @"Nike",
                        @"price": @"$135",
                        @"description": @"Customized Nike Air Force 1 low-top sneakers, classic black base matched with pink lace Swoosh embroidery, paired with double-layer lace ribbon laces that can be tied into big bows. The sweet coquette aesthetic transforms the casual sneaker into a girly Y2K style piece, easy to match skirts, dresses and daily casual outfits."
                    }
                ]
            },
            @{
                @"personaId": @"ellex",
                @"name": @"Ellex",
                @"caption": @"Building The Ideal Y2K Wardrobe, Starting With Timeless Retro Shoes.",
                @"video": @"uniserolyoka21",
                @"ratio": @1.22,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"This Pair Can Instantly Level Up Your Whole Outfit."
                ] publisherId:@"ellex"]
            }
        ];
    });
    return posts;
}

+ (NSArray<NSDictionary *> *)yk_myPosts {
    static NSArray<NSDictionary *> *posts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *publisherId = [YKPersonaCatalog yk_reviewPersonaId];
        NSString *publisherName = [YKPersonaCatalog yk_reviewPersonaDisplayName];
        posts = @[
            @{
                @"personaId": publisherId,
                @"name": publisherName,
                @"caption": @"Y2K Aesthetic Runs Through Every Small Detail Of My Daily Style.",
                @"video": @"uniserolyoka24",
                @"ratio": @1.28,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"This Entire Y2K Presentation Is So Cohesive And Beautiful.",
                    @"The Retro Tone And Texture Fit The 2000s Aesthetic Perfectly."
                ] publisherId:publisherId]
            },
            @{
                @"personaId": publisherId,
                @"name": publisherName,
                @"caption": @"Pure Y2K Nostalgic Vibe",
                @"video": @"uniserolyoka23",
                @"ratio": @1.22,
                @"remarks": [self yk_remarksWithTexts:@[
                    @"Every Frame Is Full Of 2000s Fashion Atmosphere."
                ] publisherId:publisherId]
            }
        ];
    });
    return posts;
}

+ (NSArray<NSDictionary *> *)yk_postsForPersonaId:(NSString *)personaId {
    if (personaId.length == 0) {
        return @[];
    }
    NSMutableArray<NSDictionary *> *matched = [NSMutableArray array];
    NSMutableSet<NSString *> *seen = [NSMutableSet set];
    for (NSDictionary *entry in [self yk_allPosts]) {
        if (![entry[@"personaId"] isEqualToString:personaId]) {
            continue;
        }
        NSString *video = entry[@"video"];
        NSString *image = entry[@"image"];
        NSString *token = video.length > 0 ? [NSString stringWithFormat:@"v:%@", video]
                                          : (image.length > 0 ? [NSString stringWithFormat:@"i:%@", image] : nil);
        if (token.length == 0 || [seen containsObject:token]) {
            continue;
        }
        [seen addObject:token];
        [matched addObject:entry];
    }
    return matched;
}

+ (NSArray<NSDictionary *> *)yk_allPosts {
    static NSArray<NSDictionary *> *posts = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray<NSArray<NSDictionary *> *> *buckets = @[
            [self yk_outfitPosts],
            [self yk_makeupPosts],
            [self yk_hairPosts],
            [self yk_jewelryPosts],
            [self yk_shoesPosts],
            [self yk_myPosts]
        ];
        NSMutableArray<NSDictionary *> *merged = [NSMutableArray array];
        NSMutableSet<NSString *> *seen = [NSMutableSet set];
        for (NSArray<NSDictionary *> *bucket in buckets) {
            for (NSDictionary *entry in bucket) {
                NSString *video = entry[@"video"];
                NSString *image = entry[@"image"];
                NSString *token = video.length > 0 ? [NSString stringWithFormat:@"v:%@", video]
                                                  : (image.length > 0 ? [NSString stringWithFormat:@"i:%@", image] : nil);
                if (token.length == 0 || [seen containsObject:token]) {
                    continue;
                }
                [seen addObject:token];
                [merged addObject:entry];
            }
        }
        posts = [merged copy];
    });
    return posts;
}

@end
