# -*- encoding: utf-8 -*-
# stub: travis 1.10.0 ruby lib

Gem::Specification.new do |s|
  s.name = "travis".freeze
  s.version = "1.10.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Konstantin Haase".freeze, "Hiro Asari".freeze, "Henrik Hodne".freeze, "joshua-anderson".freeze, "Aaron Hill".freeze, "Piotr Milcarz".freeze, "Buck Doyle".freeze, "Peter Souter".freeze, "Christopher Grim".freeze, "Joe Corcoran".freeze, "Peter van Dijk".freeze, "Sven Fuchs".freeze, "Aakriti Gupta".freeze, "Josh Kalderimis".freeze, "Piotr Sarnacki".freeze, "Ke Zhu".freeze, "Max Barnash".freeze, "Ren\u00E9e Hendricksen".freeze, "carlad".freeze, "Carlos Palhares".freeze, "Dan Buch".freeze, "Mar\u00EDa de Ant\u00F3n".freeze, "Mathias Meyer".freeze, "Matt Toothman".freeze, "mariadeanton".freeze, "techgaun".freeze, "Alpha".freeze, "Andreas Tiefenthaler".freeze, "Beau Bouchard".freeze, "Corinna Wiesner".freeze, "David Rodr\u00EDguez".freeze, "Eugene".freeze, "Eugene Shubin".freeze, "Igor Wiedler".freeze, "Ivan Pozdeev".freeze, "Joep van Delft".freeze, "Stefan Nordhausen".freeze, "Thais Camilo and Konstantin Haase".freeze, "Tobias Bieniek".freeze, "Adam Baxter".freeze, "Adam Lavin".freeze, "Adrien Brault".freeze, "Alfie John".freeze, "Alo\u00EFs Th\u00E9venot".freeze, "Basarat Ali Syed".freeze, "Benjamin Manns".freeze, "Christian H\u00F6ltje".freeze, "Dani Hodovic".freeze, "Daniel Chatfield".freeze, "Dominic Jodoin".freeze, "Eli Schwartz".freeze, "Eric Herot".freeze, "Eugene K".freeze, "George Millo".freeze, "Gunter Grodotzki".freeze, "Harald Nordgren".freeze, "HaraldNordgren".freeze, "Igor".freeze, "Iulian Onofrei".freeze, "Jacob Atzen".freeze, "Jacob Burkhart".freeze, "James Nylen".freeze, "Joe Rafaniello".freeze, "Jon-Erik Schneiderhan".freeze, "Jonas Chromik".freeze, "Jonne Ha\u00DF".freeze, "Julia S.Simon".freeze, "Justin Lambert".freeze, "Laurent Petit".freeze, "Maarten van Vliet".freeze, "Marco Craveiro".freeze, "Mario Visic".freeze, "Matt".freeze, "Matteo Sumberaz".freeze, "Matthias Bussonnier".freeze, "Michael Mior".freeze, "Michael S. Fischer".freeze, "Miro Hron\u010Dok".freeze, "Neamar".freeze, "Nero Leung".freeze, "Nicolas Bessi (nbessi)".freeze, "Nikhil Owalekar".freeze, "Peter Bengtsson".freeze, "Peter Drake".freeze, "Rapha\u00EBl Pinson".freeze, "Rob Hoelz".freeze, "Robert Grider".freeze, "Robert Van Voorhees".freeze, "Simon Cropp".freeze, "Tahsin Hasan".freeze, "Titus".freeze, "Titus Wormer".freeze, "Tobias Wilken".freeze, "Zachary Gershman".freeze, "Zachary Scott".freeze, "designerror".freeze, "ia".freeze, "jeffdh".freeze, "john muhl".freeze, "slewt".freeze]
  s.date = "2020-09-22"
  s.description = "CLI and Ruby client library for Travis CI".freeze
  s.email = ["konstantin.mailinglists@googlemail.com".freeze, "asari.ruby@gmail.com".freeze, "j@zatigo.com".freeze, "aa1ronham@gmail.com".freeze, "piotrm@travis-ci.org".freeze, "me@henrikhodne.com".freeze, "b@chromatin.ca".freeze, "henrik@hodne.io".freeze, "p.morsou@gmail.com".freeze, "chrisg@luminal.io".freeze, "joe@corcoran.io".freeze, "peter.van.dijk@netherlabs.nl".freeze, "me@svenfuchs.com".freeze, "josh.kalderimis@gmail.com".freeze, "drogus@gmail.com".freeze, "kzhu@us.ibm.com".freeze, "i.am@anhero.ru".freeze, "renee@travis-ci.org".freeze, "aakritigupta@users.noreply.github.com".freeze, "me@xjunior.me".freeze, "dan@meatballhat.com".freeze, "mariadeanton@gmail.com".freeze, "meyer@paperplanes.de".freeze, "matt.toothman@aver.io".freeze, "carlad@users.noreply.github.com".freeze, "coolsamar207@gmail.com".freeze, "aakriti@travis-ci.org".freeze, "AlphaWong@users.noreply.github.com".freeze, "at@an-ti.eu".freeze, "127320+BeauBouchard@users.noreply.github.com".freeze, "wiesner@avarteq.de".freeze, "deivid.rodriguez@gmail.com".freeze, "eugene@travis-ci.org".freeze, "51701929+eugene-travis@users.noreply.github.com".freeze, "igor@travis-ci.org".freeze, "vano@mail.mipt.ru".freeze, "stefan.nordhausen@immobilienscout24.de".freeze, "dev+narwen+rkh@rkh.im".freeze, "tobias.bieniek@gmail.com".freeze, "github@voltagex.org".freeze, "adam@lavoaster.co.uk".freeze, "adrien.brault@gmail.com".freeze, "33c6c91f3bb4a391082e8a29642cafaf@alfie.wtf".freeze, "aloisthevenot@srxp.com".freeze, "basaratali@gmail.com".freeze, "benmanns@gmail.com".freeze, "docwhat@gerf.org".freeze, "danihodovic@users.noreply.github.com".freeze, "chatfielddaniel@gmail.com".freeze, "dominic@travis-ci.com".freeze, "eschwartz@archlinux.org".freeze, "eric.github@herot.com".freeze, "34233075+eugene-kulak@users.noreply.github.com".freeze, "georgejulianmillo@gmail.com".freeze, "gunter@grodotzki.co.za".freeze, "haraldnordgren@gmail.com".freeze, "igorwwwwwwwwwwwwwwwwwwww@users.noreply.github.com".freeze, "6d0847b9@opayq.com".freeze, "jatzen@gmail.com".freeze, "jburkhart@engineyard.com".freeze, "jnylen@gmail.com".freeze, "jrafanie@users.noreply.github.com".freeze, "joep@travis-ci.org".freeze, "joepvd@users.noreply.github.com".freeze, "jon-erik.schneiderhan@meyouhealth.com".freeze, "Jonas.Chromik@student.hpi.uni-potsdam.de".freeze, "me@jhass.eu".freeze, "julia.simon@biicode.com".freeze, "jlambert@eml.cc".freeze, "laurent.petit@gmail.com".freeze, "maartenvanvliet@gmail.com".freeze, "marco.craveiro@gmail.com".freeze, "mario@mariovisic.com".freeze, "mtoothman@users.noreply.github.com".freeze, "gnappoms@gmail.com".freeze, "bussonniermatthias@gmail.com".freeze, "mmior@uwaterloo.ca".freeze, "mfischer@zendesk.com".freeze, "miro@hroncok.cz".freeze, "neamar@neamar.fr".freeze, "neroleung@gmail.com".freeze, "nbessi@users.noreply.github.com".freeze, "nowalekar@tigetext.com".freeze, "peterbe@mozilla.com".freeze, "peter.drake@acquia.com".freeze, "raphael.pinson@camptocamp.com".freeze, "rob@hoelz.ro".freeze, "robert.grider@northwestern.edu".freeze, "rcvanvo@gmail.com".freeze, "simon.cropp@gmail.com".freeze, "51903216+Tahsin-travis-ci@users.noreply.github.com".freeze, "tituswormer@gmail.com".freeze, "tw@cloudcontrol.de".freeze, "pair+zg@pivotallabs.com".freeze, "e@zzak.io".freeze, "carla@travis-ci.org".freeze, "designerror@yandex.ru".freeze, "isaac.ardis@gmail.com".freeze, "jeffdh@gmail.com".freeze, "git@johnmuhl.com".freeze, "leland@lcweathers.net".freeze]
  s.executables = ["travis".freeze]
  s.files = ["bin/travis".freeze]
  s.homepage = "https://github.com/travis-ci/travis.rb".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Travis CI client".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<faraday>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<faraday_middleware>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<highline>.freeze, ["~> 2.0"])
      s.add_runtime_dependency(%q<gh>.freeze, ["~> 0.13"])
      s.add_runtime_dependency(%q<launchy>.freeze, ["~> 2.1", "< 2.5.0"])
      s.add_runtime_dependency(%q<json_pure>.freeze, ["~> 2.3"])
      s.add_runtime_dependency(%q<pusher-client>.freeze, ["~> 0.4"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 2.12"])
      s.add_development_dependency(%q<rspec-its>.freeze, [">= 0"])
      s.add_development_dependency(%q<sinatra>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<rack-test>.freeze, ["~> 0.6"])
    else
      s.add_dependency(%q<faraday>.freeze, ["~> 1.0"])
      s.add_dependency(%q<faraday_middleware>.freeze, ["~> 1.0"])
      s.add_dependency(%q<highline>.freeze, ["~> 2.0"])
      s.add_dependency(%q<gh>.freeze, ["~> 0.13"])
      s.add_dependency(%q<launchy>.freeze, ["~> 2.1", "< 2.5.0"])
      s.add_dependency(%q<json_pure>.freeze, ["~> 2.3"])
      s.add_dependency(%q<pusher-client>.freeze, ["~> 0.4"])
      s.add_dependency(%q<rspec>.freeze, ["~> 2.12"])
      s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
      s.add_dependency(%q<sinatra>.freeze, ["~> 1.3"])
      s.add_dependency(%q<rack-test>.freeze, ["~> 0.6"])
    end
  else
    s.add_dependency(%q<faraday>.freeze, ["~> 1.0"])
    s.add_dependency(%q<faraday_middleware>.freeze, ["~> 1.0"])
    s.add_dependency(%q<highline>.freeze, ["~> 2.0"])
    s.add_dependency(%q<gh>.freeze, ["~> 0.13"])
    s.add_dependency(%q<launchy>.freeze, ["~> 2.1", "< 2.5.0"])
    s.add_dependency(%q<json_pure>.freeze, ["~> 2.3"])
    s.add_dependency(%q<pusher-client>.freeze, ["~> 0.4"])
    s.add_dependency(%q<rspec>.freeze, ["~> 2.12"])
    s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
    s.add_dependency(%q<sinatra>.freeze, ["~> 1.3"])
    s.add_dependency(%q<rack-test>.freeze, ["~> 0.6"])
  end
end
