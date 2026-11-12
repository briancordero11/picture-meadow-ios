# Action-led wish journeys

The twenty original home pictures lead into the same three-part exploration. A Super Star can choose up to three actions, one broad setting or object, and the selected picture that matters most. Favorites from the separate home intake carry into each wish automatically. Next can leave a question unanswered, and Back revisits the previous part. The final on-device collage brings the chosen concepts together for a conversation with a grown-up.

The home begins with a full-width pale-yellow “What are your favorites?” card above the supplied twenty pictures in their original order. New action, setting, and favorite choices use large labeled emoji cards. Main picture cards have 16-point corners and compact communication tiles have 12-point corners. Rounded controls retain the fixed board grids, tile sizes, and unchanged source artwork. The drawer holds its thirty-four original concepts. Optional generation sends catalog IDs and has no photograph-upload step.

## Entry and shared favorites

Cold launch shows the supplied Make-A-Wish client-demo logo in white on blue #0057B8. The SwiftUI overlay holds for about 750 ms and fades for 350 ms into the mounted app. Reduce Motion removes the fade, and background returns or page changes do not replay the intro. The system launch background uses the same blue. The main Create your wish heading remains the existing typeset arch/star wordmark. Demo asset provenance is recorded separately; shipping branding and permission remain release decisions. [Logo provenance](../assets/provenance/client-demo-logo.json).

The yellow first card opens a dedicated favorites page using all six catalog groups. Every choice is optional, with a maximum of ten across the groups. One yellow Save favorites control follows the groups at the bottom, together with the storage explanation. Save returns to the topic grid and keeps the preferences with the current ideas. It does not enable storage or introduce a separate profile. A grown-up can enable Remember choices in Settings to retain them on this iPad across launches.

Favorites are edited only in the dedicated home intake and carry across topic changes. The per-topic favorites question and Keep my favorites action are removed from all twenty routes. Actions lead directly to the setting/object question, then to the most-important choice. Saved favorites remain eligible for that most-important choice and are included in the collage and optional AI request. Next, Back, and Home preserve them; starting a new wish and Forget retain their existing clearing behavior.

Privacy information, data controls, app information, and support/report actions are reached through grown-up Settings after the four-digit reading check. The main header, pause screen, and code-entry screen have no privacy link. The reading check separates tasks and does not verify guardianship or provide legal consent. Publisher, public contact, policy, and support URLs remain unconfigured.

## Back navigation

The top-left header control is a fixed Home house icon, disabled when already on the wish grid. Home returns to that grid, closes the communication board, stops speech, and preserves the current wish, favorites, board sentence, preferences, saved data, and pictures. The former Skip control is replaced by Back beside the main action. Back also appears beside Save favorites and on the final picture, so returning one page remains distinct from returning Home. No question becomes mandatory; Next may leave it unanswered.

Back selects the previous page or journey stage immediately, then the incoming main content fades from half opacity and moves 18 points into place over 300 ms. The header, communication drawer, and settings remain outside this effect. The page remains interactive, and existing scroll/choice state is retained. Reduce Motion uses an immediate update. A new page/stage, opened Settings, or an inactive scene cancels the effect. The native build passed; physical-device motion verification remains pending.

The visible step counter is replaced by a rounded 12-point progress bar. It advances or retreats through thirds as the current journey part changes, with accessible values of 33, 67, and 100 percent. The native fill uses a 320 ms smooth animation, skipped under Reduce Motion. Progress remains available to assistive technology without a visible numbered step label.

Grown-up Settings also offers Boy, Girl, Man, and Woman speech styles with preview/stop controls. The app selects an available eligible English voice and shows its real name/quality and any fallback. Boy and Girl are pitch styles of adult voices. The selection is a local preference independent of draft remembering and is reset by Forget choices.

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

The contract checker verifies twenty home IDs, choice bounds, required fields, 216 distinct IDs, and matching authoritative/native/backend catalogs. The latest verified native baseline is source commit `9b00e20`, with an unsigned build, 73 unit tests and two UI tests passing on the iPad mini (A17 Pro), iOS 26.5 simulator. The UI tests cover drawer gestures and real-code grown-up Settings navigation to Privacy & Data and App information. Favorites-intake behavior and all twenty three-part routes with automatic favorite carryover are covered by unit tests. Backend checks also passed. [Verified Mac baseline](https://github.com/briancordero11/picture-meadow-ios/actions/runs/43169927668). Eight release-record tests and portable resource checks also passed locally.

The local browser concept preview was rebuilt from the same catalog. A manual browser check completed Yosemite with two actions, a favorite color, an essential choice, and a combined collage, and verified tab taps and both drag directions without console errors. Subsequent checks verified bottom-only Save favorites, privacy only after the grown-up code, voice-style selection and preview/stop controls, and the animated progress bar. The latest three-part waterpark check confirmed 33/67/100 percent progress, the place question leading directly to the most-important choice, saved favorites in the finished collage, and Back from the collage returning to the most-important choice. The host computer offered Microsoft David and Zira; the browser styles use available local voices and retain the selection in page memory only. This preview is separate from the native app and does not establish iPad audio quality or animation frame rate. The hosted API's health and disabled direct-provider capabilities returned HTTP 200. Actual OpenAI generation remains unverified because no server key or completed provider review is configured. Physical iPad performance and accessibility review remain pending.
