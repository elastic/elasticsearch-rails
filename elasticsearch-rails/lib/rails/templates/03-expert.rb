#     $ rails new searchapp --skip --skip-bundle --template https://raw.github.com/elasticsearch/elasticsearch-rails/master/elasticsearch-rails/lib/rails/templates/03-complex.rb

# (See: 01-basic.rb, 02-pretty.rb)

# ----- Move the search form into partial ---------------------------------------------------------

puts
say_status  "View", "Moving the search form into partial template...\n", :yellow
puts        '-'*80, ''; sleep 0.5

gsub_file 'app/views/articles/index.html.erb', %r{\n<hr>.*<hr>\n}m do |match|
  create_file "app/views/articles/_search_form.html.erb", match
  "\n<%= render partial: 'search_form' %>\n"
end

git :add    => 'app/views/articles/index.html.erb app/views/articles/_search_form.html.erb'
git :commit => "-m 'Moved the search form into a partial template'"

# ----- Move the model integration into a concern -------------------------------------------------

puts
say_status  "Model", "Refactoring the model integration...\n", :yellow
puts        '-'*80, ''; sleep 0.5

create_file 'app/models/concerns/searchable.rb', <<-CODE
module Searchable
  extend ActiveSupport::Concern

  included do
    include Elasticsearch::Model
  end

  module ClassMethods
    def search(query)
      __elasticsearch__.search(
        {
          query: {
            multi_match: {
              query: query,
              fields: ['title^10', 'content']
            }
          },
          highlight: {
            pre_tags: ['<em class="label label-highlight">'],
            post_tags: ['</em>'],
            fields: {
              title:   { number_of_fragments: 0 },
              content: { fragment_size: 25 }
            }
          }
        }
      )
    end
  end
end
CODE

remove_file 'app/models/article.rb'
create_file 'app/models/article.rb', <<-CODE
class Article < ActiveRecord::Base
  include Searchable
end
CODE

git :add    => 'app/models/'
git :commit => "-m 'Refactored the Elasticsearch integration into a concern\n\nSee:\n\n* http://37signals.com/svn/posts/3372-put-chubby-models-on-a-diet-with-concerns\n* http://joshsymonds.com/blog/2012/10/25/rails-concerns-v-searchable-with-elasticsearch/'"

# ----- Add initializer ---------------------------------------------------------------------------

puts
say_status  "Application", "Adding configuration in an initializer...\n", :yellow
puts        '-'*80, ''; sleep 0.5

create_file 'config/initializers/elasticsearch.rb', <<-CODE
# Connect to specific Elasticsearch cluster
ELASTICSEARCH_URL = ENV['ELASTICSEARCH_URL'] || 'http://localhost:9200'

# Print Curl-formatted traces in development
#
if Rails.env.development?
  tracer = ActiveSupport::Logger.new(STDERR)
  tracer.level =  Logger::INFO
end

Elasticsearch::Model.client Elasticsearch::Client.new tracer: tracer, host: ELASTICSEARCH_URL
CODE

git :add    => 'config/initializers'
git :commit => "-m 'Added application initializer with Elasticsearch configuration'"

# ----- Generate and define data model for books --------------------------------------------------

puts
say_status  "Database", "Adding complex schema and data for books...\n", :yellow
puts        '-'*80, ''; sleep 0.5

generate :scaffold, "Category title"
generate :scaffold, "Book title:string content:text downloads:integer category:references"
generate :scaffold, "Author first_name last_name"
generate :scaffold, "Authorship book:references author:references"

insert_into_file "app/models/category.rb", :before => "end" do
  <<-CODE
  has_many :books
  CODE
end

insert_into_file "app/models/book.rb", :before => "end" do
  <<-CODE
  has_many :authorships
  has_many :authors, through: :authorships
  CODE
end

insert_into_file "app/models/author.rb", :before => "end" do
  <<-CODE
  has_many :authorships

  def full_name
    [first_name, last_name].join(' ')
  end
  CODE
end

# ----- Migrate the database --------------------------------------------------------------------------

rake  "db:migrate"

# ----- Create the seed data --------------------------------------------------------------------------

remove_file 'db/seeds.rb'
create_file 'db/seeds.rb', <<-CODE
# encoding: UTF-8

require 'yaml'

books = YAML.parse <<-DATA
---
- :title: Dracula
  :authors:
  - :last_name: Stoker
    :first_name: Bram
  :downloads: 12197
  :category: Fiction
  :content: |
    _3 May. Bistritz._--Left Munich at 8:35 P. M., on 1st May, arriving at
    Vienna early next morning; should have arrived at 6:46, but train was an
    hour late. Buda-Pesth seems a wonderful place, from the glimpse which I
    got of it from the train and the little I could walk through the
    streets. I feared to go very far from the station, as we had arrived
    late and would start as near the correct time as possible. The
    impression I had was that we were leaving the West and entering the
    East; the most western of splendid bridges over the Danube, which is
    here of noble width and depth, took us among the traditions of Turkish
    rule.

    We left in pretty good time, and came after nightfall to Klausenburgh.
    Here I stopped for the night at the Hotel Royale. I had for dinner, or
    rather supper, a chicken done up some way with red pepper, which was
    very good but thirsty. (_Mem._, get recipe for Mina.) I asked the
    waiter, and he said it was called "paprika hendl," and that, as it was a
    national dish, I should be able to get it anywhere along the
    Carpathians. I found my smattering of German very useful here; indeed, I
    don't know how I should be able to get on without it.

    Having had some time at my disposal when in London, I had visited the
    British Museum, and made search among the books and maps in the library
    regarding Transylvania; it had struck me that some foreknowledge of the
    country could hardly fail to have some importance in dealing with a
    nobleman of that country. I find that the district he named is in the
    extreme east of the country, just on the borders of three states,
    Transylvania, Moldavia and Bukovina, in the midst of the Carpathian
    mountains; one of the wildest and least known portions of Europe. I was
    not able to light on any map or work giving the exact locality of the
    Castle Dracula, as there are no maps of this country as yet to compare
    with our own Ordnance Survey maps; but I found that Bistritz, the post
    town named by Count Dracula, is a fairly well-known place. I shall enter
    here some of my notes, as they may refresh my memory when I talk over my
    travels with Mina.

    In the population of Transylvania there are four distinct nationalities:
    Saxons in the South, and mixed with them the Wallachs, who are the
    descendants of the Dacians; Magyars in the West, and Szekelys in the
    East and North. I am going among the latter, who claim to be descended
    from Attila and the Huns. This may be so, for when the Magyars conquered
    the country in the eleventh century they found the Huns settled in it. I
    read that every known superstition in the world is gathered into the
    horseshoe of the Carpathians, as if it were the centre of some sort of
    imaginative whirlpool; if so my stay may be very interesting. (_Mem._, I
    must ask the Count all about them.)

    I did not sleep well, though my bed was comfortable enough, for I had
    all sorts of queer dreams. There was a dog howling all night under my
    window, which may have had something to do with it; or it may have been
    the paprika, for I had to drink up all the water in my carafe, and was
    still thirsty. Towards morning I slept and was wakened by the continuous
    knocking at my door, so I guess I must have been sleeping soundly then.
    I had for breakfast more paprika, and a sort of porridge of maize flour
    which they said was "mamaliga," and egg-plant stuffed with forcemeat, a
    very excellent dish, which they call "impletata." (_Mem._, get recipe
    for this also.) I had to hurry breakfast, for the train started a little
    before eight, or rather it ought to have done so, for after rushing to
    the station at 7:30 I had to sit in the carriage for more than an hour
    before we began to move. It seems to me that the further east you go the
    more unpunctual are the trains. What ought they to be in China?

    All day long we seemed to dawdle through a country which was full of
    beauty of every kind. Sometimes we saw little towns or castles on the
    top of steep hills such as we see in old missals; sometimes we ran by
    rivers and streams which seemed from the wide stony margin on each side
    of them to be subject to great floods. It takes a lot of water, and
    running strong, to sweep the outside edge of a river clear. At every
    station there were groups of people, sometimes crowds, and in all sorts
    of attire. Some of them were just like the peasants at home or those I
    saw coming through France and Germany, with short jackets and round hats
    and home-made trousers; but others were very picturesque. The women
    looked pretty, except when you got near them, but they were very clumsy
    about the waist. They had all full white sleeves of some kind or other,
    and most of them had big belts with a lot of strips of something
    fluttering from them like the dresses in a ballet, but of course there
    were petticoats under them. The strangest figures we saw were the
    Slovaks, who were more barbarian than the rest, with their big cow-boy
    hats, great baggy dirty-white trousers, white linen shirts, and enormous
    heavy leather belts, nearly a foot wide, all studded over with brass
    nails. They wore high boots, with their trousers tucked into them, and
    had long black hair and heavy black moustaches. They are very
    picturesque, but do not look prepossessing. On the stage they would be
    set down at once as some old Oriental band of brigands. They are,
    however, I am told, very harmless and rather wanting in natural
    self-assertion.

    It was on the dark side of twilight when we got to Bistritz, which is a
    very interesting old place. Being practically on the frontier--for the
    Borgo Pass leads from it into Bukovina--it has had a very stormy
    existence, and it certainly shows marks of it. Fifty years ago a series
    of great fires took place, which made terrible havoc on five separate
    occasions. At the very beginning of the seventeenth century it underwent
    a siege of three weeks and lost 13,000 people, the casualties of war
    proper being assisted by famine and disease.

    Count Dracula had directed me to go to the Golden Krone Hotel, which I
    found, to my great delight, to be thoroughly old-fashioned, for of
    course I wanted to see all I could of the ways of the country. I was
    evidently expected, for when I got near the door I faced a
    cheery-looking elderly woman in the usual peasant dress--white
    undergarment with long double apron, front, and back, of coloured stuff
    fitting almost too tight for modesty. When I came close she bowed and
    said, "The Herr Englishman?" "Yes," I said, "Jonathan Harker." She
    smiled, and gave some message to an elderly man in white shirt-sleeves,
    who had followed her to the door. He went, but immediately returned with
    a letter:--

         "My Friend.--Welcome to the Carpathians. I am anxiously expecting
         you. Sleep well to-night. At three to-morrow the diligence will
         start for Bukovina; a place on it is kept for you. At the Borgo
         Pass my carriage will await you and will bring you to me. I trust
         that your journey from London has been a happy one, and that you
         will enjoy your stay in my beautiful land.

    "Your friend,

    "DRACULA."

- :title: Beyond Good and Evil
  :authors:
  - :last_name: Nietzsche
    :first_name: Friedrich Wilhelm
  :downloads: 8222
  :category: Philosophy
  :content: |
    SUPPOSING that Truth is a woman--what then? Is there not ground
    for suspecting that all philosophers, in so far as they have been
    dogmatists, have failed to understand women--that the terrible
    seriousness and clumsy importunity with which they have usually paid
    their addresses to Truth, have been unskilled and unseemly methods for
    winning a woman? Certainly she has never allowed herself to be won; and
    at present every kind of dogma stands with sad and discouraged mien--IF,
    indeed, it stands at all! For there are scoffers who maintain that it
    has fallen, that all dogma lies on the ground--nay more, that it is at
    its last gasp. But to speak seriously, there are good grounds for hoping
    that all dogmatizing in philosophy, whatever solemn, whatever conclusive
    and decided airs it has assumed, may have been only a noble puerilism
    and tyronism; and probably the time is at hand when it will be once
    and again understood WHAT has actually sufficed for the basis of such
    imposing and absolute philosophical edifices as the dogmatists have
    hitherto reared: perhaps some popular superstition of immemorial time
    (such as the soul-superstition, which, in the form of subject- and
    ego-superstition, has not yet ceased doing mischief): perhaps some
    play upon words, a deception on the part of grammar, or an
    audacious generalization of very restricted, very personal, very
    human--all-too-human facts. The philosophy of the dogmatists, it is to
    be hoped, was only a promise for thousands of years afterwards, as was
    astrology in still earlier times, in the service of which probably more
    labour, gold, acuteness, and patience have been spent than on any
    actual science hitherto: we owe to it, and to its "super-terrestrial"
    pretensions in Asia and Egypt, the grand style of architecture. It seems
    that in order to inscribe themselves upon the heart of humanity with
    everlasting claims, all great things have first to wander about the
    earth as enormous and awe-inspiring caricatures: dogmatic philosophy has
    been a caricature of this kind--for instance, the Vedanta doctrine in
    Asia, and Platonism in Europe. Let us not be ungrateful to it, although
    it must certainly be confessed that the worst, the most tiresome,
    and the most dangerous of errors hitherto has been a dogmatist
    error--namely, Plato's invention of Pure Spirit and the Good in Itself.
    But now when it has been surmounted, when Europe, rid of this nightmare,
    can again draw breath freely and at least enjoy a healthier--sleep,
    we, WHOSE DUTY IS WAKEFULNESS ITSELF, are the heirs of all the strength
    which the struggle against this error has fostered. It amounted to
    the very inversion of truth, and the denial of the PERSPECTIVE--the
    fundamental condition--of life, to speak of Spirit and the Good as Plato
    spoke of them; indeed one might ask, as a physician: "How did such a
    malady attack that finest product of antiquity, Plato? Had the wicked
    Socrates really corrupted him? Was Socrates after all a corrupter of
    youths, and deserved his hemlock?" But the struggle against Plato,
    or--to speak plainer, and for the "people"--the struggle against
    the ecclesiastical oppression of millenniums of Christianity (FOR
    CHRISTIANITY IS PLATONISM FOR THE "PEOPLE"), produced in Europe
    a magnificent tension of soul, such as had not existed anywhere
    previously; with such a tensely strained bow one can now aim at the
    furthest goals. As a matter of fact, the European feels this tension as
    a state of distress, and twice attempts have been made in grand style to
    unbend the bow: once by means of Jesuitism, and the second time by means
    of democratic enlightenment--which, with the aid of liberty of the press
    and newspaper-reading, might, in fact, bring it about that the spirit
    would not so easily find itself in "distress"! (The Germans invented
    gunpowder--all credit to them! but they again made things square--they
    invented printing.) But we, who are neither Jesuits, nor democrats,
    nor even sufficiently Germans, we GOOD EUROPEANS, and free, VERY free
    spirits--we have it still, all the distress of spirit and all the
    tension of its bow! And perhaps also the arrow, the duty, and, who
    knows? THE GOAL TO AIM AT....

    Sils Maria Upper Engadine, JUNE, 1885.

- :title: Ulysses
  :authors:
  - :last_name: Joyce
    :first_name: James
  :downloads: 14679
  :category: Fiction
  :content: |
    Stately, plump Buck Mulligan came from the stairhead, bearing a bowl of
    lather on which a mirror and a razor lay crossed. A yellow dressinggown,
    ungirdled, was sustained gently behind him on the mild morning air. He
    held the bowl aloft and intoned:

    --_Introibo ad altare Dei_.

    Halted, he peered down the dark winding stairs and called out coarsely:

    --Come up, Kinch! Come up, you fearful jesuit!

    Solemnly he came forward and mounted the round gunrest. He faced about
    and blessed gravely thrice the tower, the surrounding land and the
    awaking mountains. Then, catching sight of Stephen Dedalus, he bent
    towards him and made rapid crosses in the air, gurgling in his throat
    and shaking his head. Stephen Dedalus, displeased and sleepy, leaned
    his arms on the top of the staircase and looked coldly at the shaking
    gurgling face that blessed him, equine in its length, and at the light
    untonsured hair, grained and hued like pale oak.

    Buck Mulligan peeped an instant under the mirror and then covered the
    bowl smartly.

    --Back to barracks! he said sternly.

    He added in a preacher's tone:

    --For this, O dearly beloved, is the genuine Christine: body and soul
    and blood and ouns. Slow music, please. Shut your eyes, gents. One
    moment. A little trouble about those white corpuscles. Silence, all.

    He peered sideways up and gave a long slow whistle of call, then paused
    awhile in rapt attention, his even white teeth glistening here and there
    with gold points. Chrysostomos. Two strong shrill whistles answered
    through the calm.

    --Thanks, old chap, he cried briskly. That will do nicely. Switch off
    the current, will you?

    He skipped off the gunrest and looked gravely at his watcher, gathering
    about his legs the loose folds of his gown. The plump shadowed face and
    sullen oval jowl recalled a prelate, patron of arts in the middle ages.
    A pleasant smile broke quietly over his lips.

    --The mockery of it! he said gaily. Your absurd name, an ancient Greek!

    He pointed his finger in friendly jest and went over to the parapet,
    laughing to himself. Stephen Dedalus stepped up, followed him wearily
    halfway and sat down on the edge of the gunrest, watching him still as
    he propped his mirror on the parapet, dipped the brush in the bowl and
    lathered cheeks and neck.

    Buck Mulligan's gay voice went on.

    --My name is absurd too: Malachi Mulligan, two dactyls. But it has a
    Hellenic ring, hasn't it? Tripping and sunny like the buck himself.
    We must go to Athens. Will you come if I can get the aunt to fork out
    twenty quid?

    He laid the brush aside and, laughing with delight, cried:

    --Will he come? The jejune jesuit!

    Ceasing, he began to shave with care.

    --Tell me, Mulligan, Stephen said quietly.

    --Yes, my love?

    --How long is Haines going to stay in this tower?

    Buck Mulligan showed a shaven cheek over his right shoulder.

- :title: Metamorphosis
  :authors:
  - :last_name: Kafka
    :first_name: Franz
  :downloads: 22697
  :category: Fiction
  :content: |
    One morning, when Gregor Samsa woke from troubled dreams, he found
    himself transformed in his bed into a horrible vermin.  He lay on
    his armour-like back, and if he lifted his head a little he could
    see his brown belly, slightly domed and divided by arches into stiff
    sections.  The bedding was hardly able to cover it and seemed ready
    to slide off any moment.  His many legs, pitifully thin compared
    with the size of the rest of him, waved about helplessly as he
    looked.

    "What's happened to me?" he thought.  It wasn't a dream.  His room,
    a proper human room although a little too small, lay peacefully
    between its four familiar walls.  A collection of textile samples
    lay spread out on the table - Samsa was a travelling salesman - and
    above it there hung a picture that he had recently cut out of an
    illustrated magazine and housed in a nice, gilded frame.  It showed
    a lady fitted out with a fur hat and fur boa who sat upright,
    raising a heavy fur muff that covered the whole of her lower arm
    towards the viewer.

    Gregor then turned to look out the window at the dull weather.
    Drops of rain could be heard hitting the pane, which made him feel
    quite sad.  "How about if I sleep a little bit longer and forget all
    this nonsense", he thought, but that was something he was unable to
    do because he was used to sleeping on his right, and in his present
    state couldn't get into that position.  However hard he threw
    himself onto his right, he always rolled back to where he was.  He
    must have tried it a hundred times, shut his eyes so that he
    wouldn't have to look at the floundering legs, and only stopped when
    he began to feel a mild, dull pain there that he had never felt
    before.

    "Oh, God", he thought, "what a strenuous career it is that I've
    chosen! Travelling day in and day out.  Doing business like this
    takes much more effort than doing your own business at home, and on
    top of that there's the curse of travelling, worries about making
    train connections, bad and irregular food, contact with different
    people all the time so that you can never get to know anyone or
    become friendly with them.  It can all go to Hell!"  He felt a
    slight itch up on his belly; pushed himself slowly up on his back
    towards the headboard so that he could lift his head better; found
    where the itch was, and saw that it was covered with lots of little
    white spots which he didn't know what to make of; and when he tried
    to feel the place with one of his legs he drew it quickly back
    because as soon as he touched it he was overcome by a cold shudder.

    He slid back into his former position.  "Getting up early all the
    time", he thought, "it makes you stupid.  You've got to get enough
    sleep.  Other travelling salesmen live a life of luxury.  For
    instance, whenever I go back to the guest house during the morning
    to copy out the contract, these gentlemen are always still sitting
    there eating their breakfasts.  I ought to just try that with my
    boss; I'd get kicked out on the spot.  But who knows, maybe that
    would be the best thing for me.  If I didn't have my parents to
    think about I'd have given in my notice a long time ago, I'd have
    gone up to the boss and told him just what I think, tell him
    everything I would, let him know just what I feel.  He'd fall right
    off his desk! And it's a funny sort of business to be sitting up
    there at your desk, talking down at your subordinates from up there,
    especially when you have to go right up close because the boss is
    hard of hearing.  Well, there's still some hope; once I've got the
    money together to pay off my parents' debt to him - another five or
    six years I suppose - that's definitely what I'll do.  That's when
    I'll make the big change.  First of all though, I've got to get up,
    my train leaves at five."

- :title: Crime and Punishment
  :authors:
  - :last_name: Dostoyevsky
    :first_name: Fyodor
  :downloads: 4590
  :category: Fiction
  :content: |
    On an exceptionally hot evening early in July a young man came out of
    the garret in which he lodged in S. Place and walked slowly, as though
    in hesitation, towards K. bridge.

    He had successfully avoided meeting his landlady on the staircase. His
    garret was under the roof of a high, five-storied house and was more
    like a cupboard than a room. The landlady who provided him with garret,
    dinners, and attendance, lived on the floor below, and every time
    he went out he was obliged to pass her kitchen, the door of which
    invariably stood open. And each time he passed, the young man had a
    sick, frightened feeling, which made him scowl and feel ashamed. He was
    hopelessly in debt to his landlady, and was afraid of meeting her.

    This was not because he was cowardly and abject, quite the contrary; but
    for some time past he had been in an overstrained irritable condition,
    verging on hypochondria. He had become so completely absorbed in
    himself, and isolated from his fellows that he dreaded meeting, not
    only his landlady, but anyone at all. He was crushed by poverty, but the
    anxieties of his position had of late ceased to weigh upon him. He had
    given up attending to matters of practical importance; he had lost all
    desire to do so. Nothing that any landlady could do had a real terror
    for him. But to be stopped on the stairs, to be forced to listen to her
    trivial, irrelevant gossip, to pestering demands for payment, threats
    and complaints, and to rack his brains for excuses, to prevaricate, to
    lie--no, rather than that, he would creep down the stairs like a cat and
    slip out unseen.

    This evening, however, on coming out into the street, he became acutely
    aware of his fears.

    "I want to attempt a thing _like that_ and am frightened by these
    trifles," he thought, with an odd smile. "Hm... yes, all is in a man's
    hands and he lets it all slip from cowardice, that's an axiom. It would
    be interesting to know what it is men are most afraid of. Taking a new
    step, uttering a new word is what they fear most.... But I am talking
    too much. It's because I chatter that I do nothing. Or perhaps it is
    that I chatter because I do nothing. I've learned to chatter this
    last month, lying for days together in my den thinking... of Jack the
    Giant-killer. Why am I going there now? Am I capable of _that_? Is
    _that_ serious? It is not serious at all. It's simply a fantasy to amuse
    myself; a plaything! Yes, maybe it is a plaything."

    The heat in the street was terrible: and the airlessness, the bustle
    and the plaster, scaffolding, bricks, and dust all about him, and that
    special Petersburg stench, so familiar to all who are unable to get out
    of town in summer--all worked painfully upon the young man's already
    overwrought nerves. The insufferable stench from the pot-houses, which
    are particularly numerous in that part of the town, and the drunken men
    whom he met continually, although it was a working day, completed
    the revolting misery of the picture. An expression of the profoundest
    disgust gleamed for a moment in the young man's refined face. He was,
    by the way, exceptionally handsome, above the average in height, slim,
    well-built, with beautiful dark eyes and dark brown hair. Soon he sank
    into deep thought, or more accurately speaking into a complete blankness
    of mind; he walked along not observing what was about him and not caring
    to observe it. From time to time, he would mutter something, from the
    habit of talking to himself, to which he had just confessed. At these
    moments he would become conscious that his ideas were sometimes in a
    tangle and that he was very weak; for two days he had scarcely tasted
    food.

- :title: The Hound of the Baskervilles
  :authors:
  - :last_name: Doyle
    :first_name: Arthur Conan
  :downloads: 5021
  :category: Fiction
  :content: |
    Mr. Sherlock Holmes, who was usually very late in the mornings, save
    upon those not infrequent occasions when he was up all night, was seated
    at the breakfast table. I stood upon the hearth-rug and picked up the
    stick which our visitor had left behind him the night before. It was a
    fine, thick piece of wood, bulbous-headed, of the sort which is known as
    a "Penang lawyer." Just under the head was a broad silver band nearly
    an inch across. "To James Mortimer, M.R.C.S., from his friends of the
    C.C.H.," was engraved upon it, with the date "1884." It was just such a
    stick as the old-fashioned family practitioner used to carry--dignified,
    solid, and reassuring.

    "Well, Watson, what do you make of it?"

    Holmes was sitting with his back to me, and I had given him no sign of
    my occupation.

    "How did you know what I was doing? I believe you have eyes in the back
    of your head."

    "I have, at least, a well-polished, silver-plated coffee-pot in front of
    me," said he. "But, tell me, Watson, what do you make of our visitor's
    stick? Since we have been so unfortunate as to miss him and have no
    notion of his errand, this accidental souvenir becomes of importance.
    Let me hear you reconstruct the man by an examination of it."

    "I think," said I, following as far as I could the methods of my
    companion, "that Dr. Mortimer is a successful, elderly medical man,
    well-esteemed since those who know him give him this mark of their
    appreciation."

    "Good!" said Holmes. "Excellent!"

    "I think also that the probability is in favour of his being a country
    practitioner who does a great deal of his visiting on foot."

    "Why so?"

    "Because this stick, though originally a very handsome one has been so
    knocked about that I can hardly imagine a town practitioner carrying it.
    The thick-iron ferrule is worn down, so it is evident that he has done a
    great amount of walking with it."

    "Perfectly sound!" said Holmes.

    "And then again, there is the 'friends of the C.C.H.' I should guess
    that to be the Something Hunt, the local hunt to whose members he has
    possibly given some surgical assistance, and which has made him a small
    presentation in return."

    "Really, Watson, you excel yourself," said Holmes, pushing back his
    chair and lighting a cigarette. "I am bound to say that in all the
    accounts which you have been so good as to give of my own small
    achievements you have habitually underrated your own abilities. It may
    be that you are not yourself luminous, but you are a conductor of
    light. Some people without possessing genius have a remarkable power of
    stimulating it. I confess, my dear fellow, that I am very much in your
    debt."

    He had never said as much before, and I must admit that his words gave
    me keen pleasure, for I had often been piqued by his indifference to my
    admiration and to the attempts which I had made to give publicity to
    his methods. I was proud, too, to think that I had so far mastered his
    system as to apply it in a way which earned his approval. He now took
    the stick from my hands and examined it for a few minutes with his naked
    eyes. Then with an expression of interest he laid down his cigarette,
    and carrying the cane to the window, he looked over it again with a
    convex lens.

    "Interesting, though elementary," said he as he returned to his
    favourite corner of the settee. "There are certainly one or two
    indications upon the stick. It gives us the basis for several
    deductions."

- :title: Madame Bovary
  :authors:
  - :last_name: Flaubert
    :first_name: Gustave
  :downloads: 4090
  :category: Fiction
  :content: |
    We were in class when the head-master came in, followed by a "new
    fellow," not wearing the school uniform, and a school servant carrying a
    large desk. Those who had been asleep woke up, and every one rose as if
    just surprised at his work.

    The head-master made a sign to us to sit down. Then, turning to the
    class-master, he said to him in a low voice--

    "Monsieur Roger, here is a pupil whom I recommend to your care; he'll be
    in the second. If his work and conduct are satisfactory, he will go into
    one of the upper classes, as becomes his age."

    The "new fellow," standing in the corner behind the door so that he
    could hardly be seen, was a country lad of about fifteen, and taller
    than any of us. His hair was cut square on his forehead like a village
    chorister's; he looked reliable, but very ill at ease. Although he was
    not broad-shouldered, his short school jacket of green cloth with black
    buttons must have been tight about the arm-holes, and showed at the
    opening of the cuffs red wrists accustomed to being bare. His legs, in
    blue stockings, looked out from beneath yellow trousers, drawn tight by
    braces, He wore stout, ill-cleaned, hob-nailed boots.

    We began repeating the lesson. He listened with all his ears, as
    attentive as if at a sermon, not daring even to cross his legs or lean
    on his elbow; and when at two o'clock the bell rang, the master was
    obliged to tell him to fall into line with the rest of us.

    When we came back to work, we were in the habit of throwing our caps on
    the ground so as to have our hands more free; we used from the door to
    toss them under the form, so that they hit against the wall and made a
    lot of dust: it was "the thing."

    But, whether he had not noticed the trick, or did not dare to attempt
    it, the "new fellow," was still holding his cap on his knees even after
    prayers were over. It was one of those head-gears of composite order, in
    which we can find traces of the bearskin, shako, billycock hat, sealskin
    cap, and cotton night-cap; one of those poor things, in fine, whose
    dumb ugliness has depths of expression, like an imbecile's face. Oval,
    stiffened with whalebone, it began with three round knobs; then came in
    succession lozenges of velvet and rabbit-skin separated by a red band;
    after that a sort of bag that ended in a cardboard polygon covered with
    complicated braiding, from which hung, at the end of a long thin cord,
    small twisted gold threads in the manner of a tassel. The cap was new;
    its peak shone.

    "Rise," said the master.

    He stood up; his cap fell. The whole class began to laugh. He stooped to
    pick it up. A neighbor knocked it down again with his elbow; he picked
    it up once more.

- :title: Tractatus Logico-Philosophicus
  :authors:
  - :last_name: Wittgenstein
    :first_name: Ludwig
  :downloads: 4036
  :category: Philosophy
  :content: |
    1 The world is everything that is the case.∗
    1.1 The world is the totality of facts, not of things.
    1.11 The world is determined by the facts, and by these being all the facts.
    1.12 For the totality of facts determines both what is the case, and also all that is not the case.
    1.13 The facts in logical space are the world.
    1.2 The world divides into facts.
    1.21 Any one can either be the case or not be the case, and everything else remain the same.
- :title: A General Introduction to Psychoanalysis
  :authors:
  - :last_name: Freud
    :first_name: Sigmund
  :downloads: 1355
  :category: Psychology
  :content: |
    I do not know how familiar some of you may be, either from your reading
    or from hearsay, with psychoanalysis. But, in keeping with the title of
    these lectures--_A General Introduction to Psychoanalysis_--I am obliged
    to proceed as though you knew nothing about this subject, and stood in
    need of preliminary instruction.

    To be sure, this much I may presume that you do know, namely, that
    psychoanalysis is a method of treating nervous patients medically. And
    just at this point I can give you an example to illustrate how the
    procedure in this field is precisely the reverse of that which is the
    rule in medicine. Usually when we introduce a patient to a medical
    technique which is strange to him we minimize its difficulties and give
    him confident promises concerning the result of the treatment. When,
    however, we undertake psychoanalytic treatment with a neurotic patient
    we proceed differently. We hold before him the difficulties of the
    method, its length, the exertions and the sacrifices which it will cost
    him; and, as to the result, we tell him that we make no definite
    promises, that the result depends on his conduct, on his understanding,
    on his adaptability, on his perseverance. We have, of course, excellent
    motives for conduct which seems so perverse, and into which you will
    perhaps gain insight at a later point in these lectures.

    Do not be offended, therefore, if, for the present, I treat you as I
    treat these neurotic patients. Frankly, I shall dissuade you from coming
    to hear me a second time. With this intention I shall show what
    imperfections are necessarily involved in the teaching of psychoanalysis
    and what difficulties stand in the way of gaining a personal judgment. I
    shall show you how the whole trend of your previous training and all
    your accustomed mental habits must unavoidably have made you opponents
    of psychoanalysis, and how much you must overcome in yourselves in
    order to master this instinctive opposition. Of course I cannot predict
    how much psychoanalytic understanding you will gain from my lectures,
    but I can promise this, that by listening to them you will not learn how
    to undertake a psychoanalytic treatment or how to carry one to
    completion. Furthermore, should I find anyone among you who does not
    feel satisfied with a cursory acquaintance with psychoanalysis, but who
    would like to enter into a more enduring relationship with it, I shall
    not only dissuade him, but I shall actually warn him against it. As
    things now stand, a person would, by such a choice of profession, ruin
    his every chance of success at a university, and if he goes out into the
    world as a practicing physician, he will find himself in a society which
    does not understand his aims, which regards him with suspicion and
    hostility, and which turns loose upon him all the malicious spirits
    which lurk within it.
- :title: Grimms' Fairy Tales
  :authors:
  - :last_name: Grimm
    :first_name: Jacob
  - :last_name: Grimm
    :first_name: Wilhelm
  :downloads: 25050
  :content: |
    A certain king had a beautiful garden, and in the garden stood a tree
    which bore golden apples. These apples were always counted, and about
    the time when they began to grow ripe it was found that every night one
    of them was gone. The king became very angry at this, and ordered the
    gardener to keep watch all night under the tree. The gardener set his
    eldest son to watch; but about twelve o'clock he fell asleep, and in
    the morning another of the apples was missing. Then the second son was
    ordered to watch; and at midnight he too fell asleep, and in the morning
    another apple was gone. Then the third son offered to keep watch; but
    the gardener at first would not let him, for fear some harm should come
    to him: however, at last he consented, and the young man laid himself
    under the tree to watch. As the clock struck twelve he heard a rustling
    noise in the air, and a bird came flying that was of pure gold; and as
    it was snapping at one of the apples with its beak, the gardener's son
    jumped up and shot an arrow at it. But the arrow did the bird no harm;
    only it dropped a golden feather from its tail, and then flew away.
    The golden feather was brought to the king in the morning, and all the
    council was called together. Everyone agreed that it was worth more than
    all the wealth of the kingdom: but the king said, 'One feather is of no
    use to me, I must have the whole bird.'

- :title: An English Grammar
  :authors:
  - :last_name: Baskervill
    :first_name: William Malone
  - :last_name: Sewell
    :first_name: James Witt
  :downloads: 1211
  :category: Linguistics
  :content: |
    Of making many English grammars there is no end; nor should there be
    till theoretical scholarship and actual practice are more happily
    wedded. In this field much valuable work has already been
    accomplished; but it has been done largely by workers accustomed to
    take the scholar's point of view, and their writings are addressed
    rather to trained minds than to immature learners. To find an advanced
    grammar unencumbered with hard words, abstruse thoughts, and difficult
    principles, is not altogether an easy matter. These things enhance the
    difficulty which an ordinary youth experiences in grasping and
    assimilating the facts of grammar, and create a distaste for the
    study. It is therefore the leading object of this book to be both as
    scholarly and as practical as possible. In it there is an attempt to
    present grammatical facts as simply, and to lead the student to
    assimilate them as thoroughly, as possible, and at the same time to do
    away with confusing difficulties as far as may be.
DATA

[Book, Author, Authorship, Category].each { |model| model.delete_all }

books.to_ruby.each do |b|
  book = Book.create \
    title: b[:title],
    downloads: b[:downloads],
    content: b[:content]

  b[:authors].each do |a|
    author = Author.where(first_name: a[:first_name], last_name: a[:last_name]).first_or_create
    book.authors << author
  end

  category = Category.where(title: b[:category]).first_or_create
  book.category = category

  book.save
end
CODE

git :add    => '.'
git :commit => "-m 'Added data model and seed script (books, categories, authors)'"

# === TODO: ===
#
# * Update views (show authors, category name, bootstrap)
# <table class="table table-hover">
# class: 'btn btn-default btn-xs'
# class: 'btn btn-primary btn-xs', style: 'color: #fff'
# <td><%= book.authors.map(&:full_name).to_sentence %></td>
# <td><%= book.category.try(:title) || 'n/a' %></td>
# Update controller (fight n+1)
# @books = Book.includes(:authors, :category)
#

# ----- Add search support into Book model ---------------------------------------------------------

insert_into_file "app/models/book.rb", :before => "end" do
  <<-CODE

  include Searchable
  CODE
end

git :add    => 'app/models/book.rb'
git :commit => "-m 'Added search support into the Book model'"

# === TODO: ===
#
# * Create search action or controller
# @books = Book.search(params[:q]).records.includes(:authors, :category)
# * Create view
#

# ----- Insert seed data into the database ---------------------------------------------------------

puts
say_status  "Database", "Seeding the database with data...", :yellow
puts        '-'*80, ''; sleep 0.25

rake "db:seed"

# ----- Import data into Elasticsearch ------------------------------------------------------------

puts
say_status  "Index", "Indexing the database...", :yellow
puts        '-'*80, ''; sleep 0.25

# rake "environment elasticsearch:import:model CLASS='Article' FORCE=true"
run "rails runner 'Book.__elasticsearch__.client.indices.delete index: Book.__elasticsearch__.index_name rescue nil; Book.__elasticsearch__.client.indices.create index: Book.__elasticsearch__.index_name; Book.__elasticsearch__.import'"

# ----- Print Git log -----------------------------------------------------------------------------

puts
say_status  "Git", "Details about the application:", :yellow
puts        '-'*80, ''

git :tag => "complex"
git :log => "--reverse --oneline HEAD...pretty"

# ----- Start the application ---------------------------------------------------------------------

require 'net/http'
if (begin; Net::HTTP.get(URI('http://localhost:3000')); rescue Errno::ECONNREFUSED; false; rescue Exception; true; end)
  puts        "\n"
  say_status  "ERROR", "Some other application is running on port 3000!\n", :red
  puts        '-'*80

  port = ask("Please provide free port:", :bold)
else
  port = '3000'
end

puts  "", "="*80
say_status  "DONE", "\e[1mStarting the application. Open http://localhost:#{port}\e[0m", :yellow
puts  "="*80, ""

run  "rails server --port=#{port}"
