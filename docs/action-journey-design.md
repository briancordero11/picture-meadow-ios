# Action-led wish journeys

The twenty original home pictures now lead into the same four-part exploration. A Super Star can choose up to three actions, one broad setting or object, optional favorites, and the selected picture that matters most. Every part can be skipped or revisited. The final on-device collage brings the chosen concepts together for a conversation with a grown-up.

The home retains the supplied twenty pictures and original order. New action, setting, and favorite choices use large labeled emoji cards. The communication drawer retains its thirty-four original concepts. These choices represent picture concepts. The app sends catalog IDs for optional generation and has no photograph-upload step.

## Source mapping

The source PDFs remain in the owner's Downloads folder. Their bytes, rendered pages, personal examples, and forms are excluded from the repository and online generation requests.

| Supplied reference | Relevant pages | Applied design |
| --- | --- | --- |
| Super Star-Wish Guide (1).pdf | 2 | Explore with family or familiar supporters, allow a relaxed pace, and learn why an idea matters. |
| Super Star-Wish Guide (1).pdf | 3 | Its happiness, calm, inside/outside activities, and learning prompts inform simple action and favorite choices. Its four preference groups are Sensory, Movement, Communication, and Learning. |
| Super Star-Wish Guide (1).pdf | 4-8 | Sensory spaces, adaptive movement, animals, music, art, technology, building, learning, camping, and National Parks inform the journey options. |
| WishIntakeform(1).pdf | 1-2 | Favorites and inside/outside, games, family, and friends prompts inform the shared preference stage. |
| WishIntakeform(1).pdf | 3-4 | The envisioned scene and most-important-part questions inform the combined picture and essential-choice stage. |
| WVC Guidance_Wish Types and Subtypes_Last Updated 2.22.2023.pdf | 1-4 | Administrative types help distinguish an experience, an object, a room, and a gift. The catalog keeps child-facing interests as its navigation. |

Six shared favorite groups offer thirty-six authored choices covering colors, food, animals, music, game styles, and adventure themes. The intake's additional book, movie, performer, restaurant, school, and hobby prompts remain source context for future preference options.

## Twenty journeys

Each row has five action choices and four setting choices. The JSON catalog contains the exact labels, symbols, and scene-prompt fragments.

| Home picture | Actions | Settings or objects |
| --- | --- | --- |
| sporting event | Watch, cheer, play, try skills, meet players | Stadium, local field, indoor court, sports day |
| camp | Explore a trail, watch wildlife, look at stars, picnic, rest | Yosemite, forest camp, lakeside camp, backyard camp |
| athlete | Meet, practice, watch practice, learn a skill, celebrate | Field, court, track, training room |
| VR equipment | Explore, create, play, learn, relax | Space world, ocean world, building world, nature world |
| amusement park | Ride, explore, watch a show, snack, take a quiet break | Theme park, fairground, small family park, indoor park |
| school | Learn, make a project, play, read, help | Classroom, library, home learning room, school garden |
| celebrity | Meet, watch, create, make music, play | Small stage, creative studio, music room, video visit |
| art | Paint, draw, sculpt, photograph, craft | Art studio, home art corner, museum, outdoor art space |
| home | Decorate, build, play, relax, garden | Bedroom, playroom, backyard, family room |
| waterpark | Splash, slide, float, watch water, rest | Outdoor park, indoor park, splash pad, quiet pool |
| animals | Watch, learn, meet a pet, care, create a space | Wildlife setting, farm, aquarium, cozy pet space |
| bike | Ride, explore, learn, decorate, ride together | Park path, neighborhood, adaptive bike, tandem bike |
| hospital | Give, make artwork, create play space, share music, help | Playroom, art wall, comfort corner, courtyard garden |
| party | Dance, play, listen, share a treat, decorate | Backyard party, indoor party, picnic party, art party |
| gift | Build, create, play, learn, share | Custom brick creation, creative computer, gaming computer, creative kit |
| train | Ride, watch, learn, build a train world, explore | Scenic train, historic train, model train, museum |
| playground | Swing, slide, climb, build, play together | Community playground, backyard playset, playhouse, indoor playground |
| music | Listen, play, sing, make a song, move | Music room, small stage, recording space, outdoor music |
| sensory room | Relax, explore lights, listen, explore textures, move | Calm room, sensory playroom, nature corner, sound corner |
| fishing | Fish, watch water, learn, picnic, explore | Lake, river, fishing pier, local pond |

WVC reference mappings include Celebrity/Sporting Event and Animal (page 1), Computer and Electronics (pages 1-2), Construction and Room Redecoration (pages 1 and 3), Education/Scholarship (page 2), Philanthropic, Music Related, Party/Celebration, and Playhouse/Playset (page 3), plus Sporting Equipment and Travel (page 4). The specific request determines its final organizational classification.

## Yosemite, camping, and gifts

Yosemite is the user's camp example, represented by granite cliffs and pine trees. Super Star pages 4, 5, and 8 offer camping or National Parks. WVC page 4 classifies camping experiences as Travel-Domestic or Other when local, camping equipment as Sporting Equipment, and gifted campers as Trailer/Camper. Gift choices include an imaginative brick build and creative or gaming computer. Settings express imagined concepts. Real availability, access, attractions, products, and fulfillment require separate arrangements.

The WVC guidance is dated February 22, 2023. Some historical destination examples in that document are time-sensitive. The new catalog uses broad settings and the user's Yosemite example rather than building a current attraction directory.

## Scene generation and grown-up control

The offline collage combines the chosen cards. Optional generation requires a grown-up's per-request confirmation and subsequent image review. Only catalog IDs are sent. The server resolves them into authored prompt fragments for one coherent imagined scene, emphasizing the most-important concept. The AI image can be removed independently of the selections.

The selected integration uses the direct OpenAI Images API with target model `gpt-image-2.5-flare` and native provider label `OpenAI (direct)`. Direct OpenAI credentials remain unconfigured. The server requires its generation flag and service access token alongside provider credentials. Native configuration requires the generation flag, HTTPS API origin, provider name, and grown-up-configured service access token. The hosted API exists, while native defaults keep the origin empty and scenes disabled. A successful production image request remains unverified. Actual provider-account access and data-handling approval, including any required Zero Data Retention arrangement, require account-level verification.

The intake form is blank, including its form field values. Its name, birth date, address, phone, email, medical-provider fields, family notes, and volunteer records do not enter the catalog or scene payload. Published children, ages, and diagnoses in the Super Star guide are also excluded from the new options and prompts.

## Document workflow and the requested feature

The user's request authorizes the twenty journeys, favorites, combined picture concepts, optional AI scenes, and Yosemite example. The PDFs provide reference concepts and organizational workflow context.

Super Star page 2 describes internal and medical approval, safety, and age appropriateness. WVC page 1 describes the organization's "Wish Determined" status. The intake's page 3 instruction asks volunteers for two ideas including a local idea. That volunteer workflow does not add an app completion requirement. Real approval, applications, arrangements, and fulfillment remain with the responsible organization.

## Verification

The contract checker compares `assets/journey-catalog.json` with native and available backend copies. It verifies twenty home IDs and order, count bounds, required fields, slug IDs, and 216 distinct choice IDs. An unsigned native build and 58 unit tests passed for commit `fa3aab0`. The subsequent tap/drag UI-test target and direct-provider label await a second CI result. Physical iPad and live-provider verification remain pending. [58-test Mac CI result](https://github.com/briancordero11/picture-meadow-ios/actions/runs/43149946910)
