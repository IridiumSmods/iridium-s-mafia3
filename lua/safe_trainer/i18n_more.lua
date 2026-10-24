-- Italian, Portuguese (Brazil), Polish, Turkish and Czech for the trainer: the
-- same keys as I18n.S, I18n.Legacy, I18n.LegacyPrefixes and I18n.LegacyWords in
-- i18n.lua. Each row is { it, pt, pl, tr, cs }; the end of this file appends the
-- rows to those tables, so a row missing here falls back to English.

I18n.More = { S = {}, Legacy = {}, Prefixes = {}, Words = {} }
local S, L = I18n.More.S, I18n.More.Legacy

-- root sections
S.sec_player = { "Giocatore", "Jogador", "Gracz", "Oyuncu", "Hráč" }
S.sec_player_d = { "Salute, invincibilità, armi, soldi, aspetto", "Vida, modo deus, armas, dinheiro, visual",
	"Zdrowie, nieśmiertelność, broń, pieniądze, wygląd", "Sağlık, ölümsüzlük, silahlar, para, görünüm",
	"Zdraví, nesmrtelnost, zbraně, peníze, vzhled" }
S.sec_vehicle = { "Veicoli", "Veículos", "Pojazdy", "Araçlar", "Vozidla" }
S.sec_vehicle_d = { "Fai apparire un'auto o una barca, riparazione, messa a punto della tua auto",
	"Gerar carro ou barco, conserto, ajustes do seu carro", "Przywołaj auto lub łódź, naprawa, tuning twojego auta",
	"Araba veya tekne çağır, onar, kendi arabanı ayarla", "Přivolej auto nebo loď, oprava, úpravy tvého auta" }
S.sec_people = { "Persone", "Pessoas", "Ludzie", "İnsanlar", "Lidé" }
S.sec_people_d = { "Da 1 a 7 persone: tiratori, corpo a corpo, pugni", "De 1 a 7 pessoas: atiradores, corpo a corpo, punhos",
	"Od 1 do 7 osób: strzelcy, walka wręcz, pięści", "1 ile 7 kişi: nişancılar, yakın dövüş, yumruklar",
	"1 až 7 lidí: střelci, boj zblízka, pěsti" }
S.sec_world = { "Mondo", "Mundo", "Świat", "Dünya", "Svět" }
S.sec_world_d = { "Ora, meteo, traffico, polizia", "Hora, clima, trânsito, polícia", "Czas, pogoda, ruch, policja",
	"Saat, hava, trafik, polis", "Čas, počasí, provoz, policie" }
S.sec_camera = { "Telecamera", "Câmera", "Kamera", "Kamera", "Kamera" }
S.sec_camera_d = { "Prima persona e telecamera libera", "Primeira pessoa e câmera livre", "Widok z pierwszej osoby i wolna kamera",
	"Birinci şahıs ve serbest kamera", "Pohled z první osoby a volná kamera" }
S.sec_settings = { "Impostazioni", "Configurações", "Ustawienia", "Ayarlar", "Nastavení" }
S.sec_settings_d = { "Lingua e autotest del trainer", "Idioma e autoteste do trainer", "Język i autotest trainera",
	"Dil ve trainer öz denetimi", "Jazyk a autotest traineru" }

-- player
S.grp_quick = { "Rapido", "Rápido", "Szybko", "Hızlı", "Rychle" }
S.heal = { "Cura", "Curar", "Ulecz", "İyileş", "Vyléčit" }
S.heal_d = { "Salute piena subito", "Vida cheia agora mesmo", "Pełne zdrowie od razu", "Hemen tam sağlık", "Plné zdraví hned teď" }
S.god = { "Invincibilità", "Modo deus", "Nieśmiertelność", "Ölümsüzlük", "Nesmrtelnost" }
S.god_d = { "Nessun danno passa. Se il gioco lo azzera dopo una morte o un caricamento, il trainer lo rimette",
	"Nenhum dano passa. Se o jogo zerar após uma morte ou carregamento, o trainer restaura",
	"Żadne obrażenia nie przechodzą. Jeśli gra zresetuje to po śmierci lub wczytaniu, trainer przywróci",
	"Hiç hasar geçmez. Oyun ölümden veya yüklemeden sonra sıfırlarsa trainer geri açar",
	"Žádné poškození neprojde. Když to hra po smrti nebo načtení vypne, trainer to vrátí" }
S.ammo = { "Ricarica munizioni", "Recarregar munição", "Uzupełnij amunicję", "Mermi doldur", "Doplnit náboje" }
S.ammo_d = { "Munizioni piene per ogni arma", "Munição cheia para todas as armas", "Pełna amunicja do każdej broni",
	"Her silah için tam mermi", "Plná munice do všech zbraní" }
S.infammo = { "Munizioni infinite", "Munição infinita", "Nieskończona amunicja", "Sonsuz mermi", "Nekonečné náboje" }
S.infammo_d = { "Il caricatore non si svuota mai", "O pente nunca acaba", "Magazynek nigdy się nie kończy", "Şarjör hiç bitmez",
	"Zásobník se nikdy nevyprázdní" }
S.grp_arsenal = { "Arsenale", "Arsenal", "Arsenał", "Cephanelik", "Arzenál" }
S.giveweapon = { "Dai arma", "Dar arma", "Daj broń", "Silah ver", "Dát zbraň" }
S.giveweapon_d = { "Sostituisce l'arma in mano, 500 colpi", "Substitui a arma na mão, 500 balas", "Zastępuje broń w ręku, 500 naboi",
	"Eldeki silahı değiştirir, 500 mermi", "Nahradí zbraň v ruce, 500 nábojů" }
S.grenades = { "Granate  ·  +2", "Granadas  ·  +2", "Granaty  ·  +2", "El bombası  ·  +2", "Granáty  ·  +2" }
S.molotovs = { "Molotov  ·  +2", "Molotovs  ·  +2", "Koktajle Mołotowa  ·  +2", "Molotof  ·  +2", "Molotovy  ·  +2" }
S.clearinv = { "Svuota inventario", "Esvaziar inventário", "Wyczyść ekwipunek", "Envanteri boşalt", "Vyprázdnit inventář" }
S.clearinv_d = { "Toglie tutte le armi", "Remove todas as armas", "Zabiera całą broń", "Tüm silahları alır", "Odebere všechny zbraně" }
S.grp_res = { "Risorse", "Recursos", "Zasoby", "Kaynaklar", "Zdroje" }
S.money = { "Soldi  ·  +5000", "Dinheiro  ·  +5000", "Pieniądze  ·  +5000", "Para  ·  +5000", "Peníze  ·  +5000" }
S.relays = { "Relè  ·  +5", "Relés  ·  +5", "Przekaźniki  ·  +5", "Röle  ·  +5", "Relé  ·  +5" }
S.relays_d = { "Pezzi per intercettare i quartieri", "Peças para grampear os distritos", "Części do podsłuchu dzielnic",
	"Bölgeleri dinlemek için parçalar", "Součástky pro odposlech čtvrtí" }
S.grp_look = { "Aspetto", "Visual", "Wygląd", "Görünüm", "Vzhled" }
S.smoke = { "Fuma", "Fumar", "Zapal", "Sigara iç", "Zakouřit" }
S.smoke_d = { "Animazioni di fumo per Lincoln", "Animações de fumar para o Lincoln", "Animacje palenia dla Lincolna",
	"Lincoln için sigara animasyonları", "Animace kouření pro Lincolna" }
S.model = { "Cambia aspetto", "Mudar visual", "Zmień wygląd", "Görünümü değiştir", "Změnit vzhled" }
S.model_d = { "Qualsiasi profilo personaggio del gioco", "Qualquer perfil de personagem do jogo", "Dowolny profil postaci z gry",
	"Oyundaki herhangi bir karakter profili", "Jakýkoli profil postavy ze hry" }
S.visible = { "Modello visibile", "Modelo visível", "Model widoczny", "Model görünür", "Model viditelný" }
S.grp_extra = { "Avanzate", "Avançado", "Zaawansowane", "Gelişmiş", "Pokročilé" }
S.noclip = { "Noclip", "Noclip", "Noclip", "Noclip", "Noclip" }
S.noclip_d = { "Volo libero con WASD, anche in auto", "Voo livre com WASD, também no carro", "Swobodny lot na WASD, także w aucie",
	"WASD ile serbest uçuş, arabada da", "Volný let na WASD, i v autě" }
S.aimcar = { "Sali nell'auto mirata", "Entrar no carro mirado", "Wsiądź do auta w celowniku", "Nişan alınan arabaya bin",
	"Nastoupit do zaměřeného auta" }
S.aimcar_d = { "Mira un'auto e premi", "Mire em um carro e aperte", "Wyceluj w auto i naciśnij", "Bir arabaya nişan al ve bas",
	"Zaměř auto a stiskni" }
S.unlock = { "Ripristina i comandi", "Restaurar controles", "Przywróć sterowanie", "Kontrolü geri ver", "Obnovit ovládání" }
S.unlock_d = { "Se il gioco ha bloccato i comandi e Lincoln non risponde", "Se o jogo travou os controles e o Lincoln não responde",
	"Jeśli gra zablokowała sterowanie i Lincoln nie reaguje", "Oyun kontrolleri kilitlediyse ve Lincoln tepki vermiyorsa",
	"Když hra zablokovala ovládání a Lincoln nereaguje" }
S.lockctl = { "Blocca i comandi", "Travar controles", "Blokada sterowania", "Kontrolleri kilitle", "Zamknout ovládání" }
S.cloth = { "Simulazione dei vestiti", "Simulação de roupas", "Symulacja ubrań", "Kıyafet simülasyonu", "Simulace oblečení" }
S.physics = { "Fisica del corpo", "Física do corpo", "Fizyka ciała", "Vücut fiziği", "Fyzika těla" }
S.pinfo = { "Info giocatore", "Info do jogador", "Informacje o graczu", "Oyuncu bilgisi", "Info o hráči" }
S.mobility = { "Movimento", "Movimento", "Ruch", "Hareket", "Pohyb" }
S.mobility_d = { "Super corsa, salto e super salto senza noclip", "Supercorrida, pulo e superpulo sem noclip",
	"Superbieg, skok i superskok bez noclipa", "Süper koşu, zıplama ve süper zıplama, noclip olmadan",
	"Superběh, skok a superskok bez noclipu" }
S.grp_mobility_run = { "Velocità", "Velocidade", "Prędkość", "Hız", "Rychlost" }
S.grp_mobility_jump = { "Salti", "Pulos", "Skoki", "Zıplamalar", "Skoky" }
S.super_run = { "Super corsa", "Supercorrida", "Superbieg", "Süper koşu", "Superběh" }
S.super_run_d = { "Il passo di Lincoln si allunga del fattore scelto: camminata, corsa e scatto. Muri e scale come nel gioco",
	"A passada do Lincoln fica maior pelo fator escolhido: andar, correr e disparar. Paredes e escadas como no jogo",
	"Krok Lincolna wydłuża się o wybrany mnożnik: chód, bieg i sprint. Ściany i schody jak w grze",
	"Lincoln'ün adımı seçilen kat kadar uzar: yürüme, koşma ve depar. Duvarlar ve merdivenler oyundaki gibi",
	"Krok Lincolna se prodlouží o zvolený násobek: chůze, běh i sprint. Zdi a schody jako ve hře" }
S.run_off = { "Normale", "Normal", "Normalny", "Normal", "Normální" }
S.run_x15 = { "x1.5", "x1.5", "x1.5", "x1.5", "x1.5" }
S.run_x2 = { "x2", "x2", "x2", "x2", "x2" }
S.run_x3 = { "x3", "x3", "x3", "x3", "x3" }
S.run_x5 = { "x5", "x5", "x5", "x5", "x5" }
S.super_run_set = { "Corsa: %s", "Corrida: %s", "Bieg: %s", "Koşu: %s", "Běh: %s" }
S.jump = { "Salto", "Pulo", "Skok", "Zıpla", "Skok" }
S.jump_d = { "Breve balzo in alto e in avanti", "Pulo curto para cima e para frente", "Krótki skok w górę i do przodu",
	"Yukarı ve ileri kısa sıçrama", "Krátký skok nahoru a dopředu" }
S.super_jump = { "Super salto", "Superpulo", "Superskok", "Süper zıplama", "Superskok" }
S.super_jump_d = { "Grande balzo verso l'alto", "Pulo alto para cima", "Wysoki skok w górę", "Yükseğe sıçrama", "Vysoký skok nahoru" }
S.jump_in_car = { "Prima scendi dall'auto", "Saia do carro primeiro", "Najpierw wysiądź z auta", "Önce arabadan in",
	"Nejdřív vystup z auta" }
S.jump_locked = { "I comandi sono bloccati ora", "Os controles estão travados agora", "Sterowanie jest teraz zablokowane",
	"Kontroller şu an kilitli", "Ovládání je teď zamčené" }
S.jump_fail = { "non riuscito", "falhou", "nie udało się", "başarısız", "nepovedlo se" }
S.grp_brawl = { "Rissa", "Briga", "Bójka", "Kavga", "Rvačka" }
S.brawl_mode = { "Modalità rissa", "Modo briga", "Tryb bójki", "Kavga modu", "Režim rvačky" }
S.brawl_mode_d = { "Solo pugni. Q dà pugni. Q finisce un nemico solo dopo il numero di colpi scelto. Un civile non si stende con un solo Q, solo dopo una serie di colpi (patch APPLY_STREET_MELEE.bat)",
	"Só punhos. Q dá socos. Q finaliza um inimigo só após o número de golpes definido. Um civil não cai com um Q só, apenas após uma surra (patch APPLY_STREET_MELEE.bat)",
	"Tylko pięści. Q to ciosy. Q dobije wroga dopiero po ustalonej liczbie ciosów. Cywila nie znokautujesz jednym Q, dopiero po serii ciosów (łatka APPLY_STREET_MELEE.bat)",
	"Sadece yumruk. Q ile vurursun. Q bir düşmanı ancak ayarlanan vuruş sayısından sonra bitirir. Bir sivil tek Q ile bayılmaz, ancak dayaktan sonra (yama APPLY_STREET_MELEE.bat)",
	"Jen pěsti. Q jsou rány. Q dorazí nepřítele až po nastaveném počtu ran. Civilistu jedním Q neknokautuješ, jen po sérii ran (patch APPLY_STREET_MELEE.bat)" }
S.brawl_hits = { "Colpi prima del colpo finale", "Golpes antes da finalização", "Ciosy przed dobiciem", "Bitirişten önce vuruş",
	"Rány před dorazem" }
S.brawl_hits_d = { "Quanti colpi incassa un nemico prima di restare stordito e Q può finirlo",
	"Quantos golpes um inimigo aguenta antes de ficar atordoado e o Q poder finalizá-lo",
	"Ile ciosów wróg wytrzyma, zanim się zachwieje i Q będzie mógł go dobić",
	"Bir düşman sersemlemeden ve Q onu bitirebilmeden önce kaç vuruş dayanır",
	"Kolik ran nepřítel vydrží, než se zapotácí a Q ho může dorazit" }
S.brawl_hits_few = { "Pochi (4)", "Poucos (4)", "Mało (4)", "Az (4)", "Málo (4)" }
S.brawl_hits_mid = { "Medio (7)", "Médio (7)", "Średnio (7)", "Orta (7)", "Středně (7)" }
S.brawl_hits_many = { "Molti (10)", "Muitos (10)", "Dużo (10)", "Çok (10)", "Hodně (10)" }
S.brawl_hit_fmt = { "Colpi: %d/%d", "Golpes: %d/%d", "Ciosy: %d/%d", "Vuruş: %d/%d", "Rány: %d/%d" }
S.brawl_ready = { "Pronto da finire (Q)", "Pronto para finalizar (Q)", "Można dobić (Q)", "Bitirmeye hazır (Q)", "Lze dorazit (Q)" }
S.brawl_early_fmt = { "Troppo presto per finire: %d/%d — Q aspetta che si riprenda",
	"Cedo demais para finalizar: %d/%d — Q espera ele se recuperar",
	"Za wcześnie na dobicie: %d/%d — Q czeka, aż dojdzie do siebie",
	"Bitirmek için çok erken: %d/%d — Q kendine gelmesini bekliyor",
	"Na doraz je brzy: %d/%d — Q čeká, až se vzpamatuje" }
S.brawl_rules_fmt = { "Q dà pugni. Q finisce un nemico dopo %d colpi; un solo Q non stende più un civile",
	"Q dá socos. Q finaliza um inimigo após %d golpes; um Q só não derruba mais um civil",
	"Q to ciosy. Q dobije wroga po %d ciosach; jedno Q nie nokautuje już cywila",
	"Q ile vurursun. Q bir düşmanı %d vuruştan sonra bitirir; tek Q artık sivili bayıltmaz",
	"Q jsou rány. Q dorazí nepřítele po %d ranách; jedno Q už civilistu neknokautuje" }
S.brawl_on = { "Modalità rissa attiva", "Modo briga ligado", "Tryb bójki włączony", "Kavga modu açık", "Režim rvačky zapnut" }
S.brawl_on_ok = { "Modalità rissa attiva (%s)", "Modo briga ligado (%s)", "Tryb bójki włączony (%s)", "Kavga modu açık (%s)",
	"Režim rvačky zapnut (%s)" }
S.brawl_fail = { "La rissa non ha preso — stile di controllo: %s", "A briga não pegou — estilo de controle: %s",
	"Bójka się nie włączyła — styl sterowania: %s", "Kavga uygulanmadı — kontrol stili: %s",
	"Rvačka se nepoužila — styl ovládání: %s" }
S.brawl_off = { "Modalità rissa disattivata", "Modo briga desligado", "Tryb bójki wyłączony", "Kavga modu kapalı",
	"Režim rvačky vypnut" }

-- smoking
S.smoke_puff = { "Fai un tiro", "Dar uma tragada", "Zaciągnij się", "Bir nefes çek", "Potáhnout" }
S.smoke_stand = { "Fuma in piedi", "Fumar em pé", "Zapal na stojąco", "Ayakta sigara iç", "Kouřit vestoje" }
S.smoke_sit = { "Siediti a fumare", "Sentar e fumar", "Usiądź i zapal", "Oturup sigara iç", "Sednout si a zakouřit" }
S.smoke_stop = { "Basta", "Parar", "Wystarczy", "Yeter", "Dost" }
S.smoke_stop_d = { "Interrompe l'animazione e restituisce subito i comandi", "Interrompe a animação e devolve o controle na hora",
	"Przerywa animację i od razu oddaje sterowanie", "Animasyonu keser ve kontrolü hemen geri verir",
	"Přeruší animaci a hned vrátí ovládání" }
S.fam_cig = { "sigaretta", "cigarro", "papieros", "sigara", "cigareta" }
S.fam_think = { "sigaretta, pensieroso", "cigarro, pensativo", "papieros, w zamyśleniu", "sigara, düşünceli", "cigareta, zamyšleně" }
S.fam_foreman = { "caposquadra", "capataz", "brygadzista", "ustabaşı", "předák" }
S.fam_joint = { "spinello", "baseado", "skręt", "sarma", "joint" }
S.fam_bum = { "vagabondo", "andarilho", "włóczęga", "serseri", "tulák" }
S.fam_guard = { "guardia", "guarda", "strażnik", "bekçi", "strážný" }
S.fam_sitjoint = { "spinello seduto", "baseado sentado", "skręt na siedząco", "oturarak sarma", "joint vsedě" }

-- vehicles
S.spawncar = { "Fai apparire un'auto", "Gerar carro", "Przywołaj auto", "Araba çağır", "Přivolat auto" }
S.spawncar_d = { "Appare 8 m davanti a te, senza farti salire", "Aparece 8 m à sua frente, sem te obrigar a entrar",
	"Pojawi się 8 m przed tobą, nie wsadzi cię do środka", "8 m önünde belirir, seni bindirmez",
	"Objeví se 8 m před tebou, nastupovat nemusíš" }
S.spawnboat = { "Fai apparire una barca", "Gerar barco", "Przywołaj łódź", "Tekne çağır", "Přivolat loď" }
S.spawnboat_d = { "Mettiti vicino all'acqua: la barca appare a 10 m dove guardi",
	"Fique perto da água: o barco aparece a 10 m para onde você olha",
	"Stań przy wodzie: łódź pojawi się 10 m w kierunku wzroku",
	"Suyun yanında dur: tekne baktığın yönde 10 m ileride belirir",
	"Postav se k vodě: loď se objeví 10 m ve směru pohledu" }
S.repair = { "Ripara l'auto", "Consertar carro", "Napraw auto", "Arabayı onar", "Opravit auto" }
S.repair_d = { "Carrozzeria e motore, la velocità resta", "Lataria e motor, a velocidade é mantida", "Karoseria i silnik, prędkość zostaje",
	"Kaporta ve motor, hız korunur", "Karoserie a motor, rychlost zůstane" }
S.curcar = { "Auto attuale", "Carro atual", "Obecne auto", "Mevcut araba", "Aktuální auto" }
S.curcar_d = { "Motore, fari, protezione, tuning. Disponibile quando sei in auto",
	"Motor, faróis, proteção, tuning. Disponível quando você está no carro",
	"Silnik, światła, ochrona, tuning. Dostępne, gdy jesteś w aucie",
	"Motor, farlar, koruma, tuning. Arabadayken kullanılabilir",
	"Motor, světla, ochrana, tuning. Dostupné, když sedíš v autě" }
S.quick_police = { "Volante della polizia", "Viatura policial", "Radiowóz", "Polis arabası", "Policejní vůz" }
S.quick_military = { "Pickup militare", "Picape militar", "Wojskowy pickup", "Askeri pikap", "Vojenský pickup" }
S.quick_truck = { "Camion", "Caminhão", "Ciężarówka", "Kamyon", "Náklaďák" }
S.grp_popular = { "Popolari", "Populares", "Popularne", "Popüler", "Oblíbené" }
S.grp_all = { "Tutti", "Todos", "Wszystkie", "Tümü", "Vše" }
S.allcars = { "Tutte le auto", "Todos os carros", "Wszystkie auta", "Tüm arabalar", "Všechna auta" }
S.boats = { "Barche", "Barcos", "Łodzie", "Tekneler", "Lodě" }
S.cars = { "Auto", "Carros", "Auta", "Arabalar", "Auta" }
S.search_part = { "parte del nome", "parte do nome", "część nazwy", "adın bir kısmı", "část názvu" }
S.list_not_loaded = { "Lista non ancora caricata", "Lista ainda não carregada", "Lista jeszcze niewczytana", "Liste henüz yüklenmedi",
	"Seznam ještě není načten" }
S.grp_drive = { "Guida", "Direção", "Jazda", "Sürüş", "Jízda" }
S.boost = { "Spinta  ·  +10", "Impulso  ·  +10", "Przyspiesz  ·  +10", "Hızlandır  ·  +10", "Zrychlit  ·  +10" }
S.engine = { "Motore", "Motor", "Silnik", "Motor", "Motor" }
S.lights = { "Fari", "Faróis", "Światła", "Farlar", "Světla" }
S.siren = { "Sirena", "Sirene", "Syrena", "Siren", "Siréna" }
S.radio = { "Radio", "Rádio", "Radio", "Radyo", "Rádio" }
S.grp_protect = { "Protezione", "Proteção", "Ochrona", "Koruma", "Ochrana" }
S.vgod = { "Invulnerabile", "Invulnerável", "Niezniszczalny", "Hasar almaz", "Nezničitelné" }
S.noexplode = { "Non esplode", "Não explode", "Nie wybucha", "Patlamaz", "Nevybuchne" }
S.nodespawn = { "Non sparisce", "Não some", "Nie znika", "Kaybolmaz", "Nezmizí" }
S.nodespawn_d = { "Il gioco non toglie l'auto quando ti allontani", "O jogo não remove o carro quando você se afasta",
	"Gra nie usunie auta, gdy odejdziesz", "Uzaklaştığında oyun arabayı kaldırmaz", "Hra auto neodstraní, když odejdeš" }
S.tires = { "Gomme antiproiettile", "Pneus à prova de balas", "Kuloodporne opony", "Kurşun geçirmez lastikler",
	"Neprůstřelné pneumatiky" }
S.grp_body = { "Carrozzeria e tuning", "Lataria e tuning", "Karoseria i tuning", "Kaporta ve tuning", "Karoserie a tuning" }
S.doors = { "Cofano, bagagliaio, finestrini", "Capô, porta-malas, vidros", "Maska, bagażnik, szyby", "Kaput, bagaj, camlar",
	"Kapota, kufr, okna" }
S.looks = { "Aspetto", "Aparência", "Wygląd", "Görünüm", "Vzhled" }
S.state = { "Condizioni e sterzo", "Condição e direção", "Stan i kierownica", "Durum ve direksiyon", "Stav a řízení" }
S.vinfo = { "Info auto", "Info do carro", "Informacje o aucie", "Araba bilgisi", "Info o autě" }
S.launch = { "Lancia in aria", "Lançar para cima", "Podrzuć", "Havaya fırlat", "Vyhodit do vzduchu" }
S.leave = { "Scendi dall'auto", "Sair do carro", "Wysiądź z auta", "Arabadan in", "Vystoupit z auta" }
S.hood = { "Cofano aperto", "Capô aberto", "Maska otwarta", "Kaput açık", "Kapota otevřená" }
S.trunk = { "Bagagliaio aperto", "Porta-malas aberto", "Bagażnik otwarty", "Bagaj açık", "Kufr otevřený" }
S.win_fl = { "Finestrino del guidatore aperto", "Vidro do motorista aberto", "Szyba kierowcy otwarta", "Sürücü camı açık",
	"Okno řidiče otevřené" }
S.win_fr = { "Finestrino del passeggero aperto", "Vidro do passageiro aberto", "Szyba pasażera otwarta", "Yolcu camı açık",
	"Okno spolujezdce otevřené" }
S.win_rl = { "Finestrino posteriore sinistro aperto", "Vidro traseiro esquerdo aberto", "Tylna lewa szyba otwarta",
	"Arka sol cam açık", "Zadní levé okno otevřené" }
S.win_rr = { "Finestrino posteriore destro aperto", "Vidro traseiro direito aberto", "Tylna prawa szyba otwarta",
	"Arka sağ cam açık", "Zadní pravé okno otevřené" }
S.colors = { "Colori della vernice", "Cores da pintura", "Kolory lakieru", "Boya renkleri", "Barvy laku" }
S.tint = { "Vetri oscurati", "Película dos vidros", "Przyciemnienie szyb", "Cam filmi", "Tónování skel" }
S.wheels_f = { "Cerchi anteriori", "Rodas dianteiras", "Przednie felgi", "Ön jantlar", "Přední kola" }
S.wheels_r = { "Cerchi posteriori", "Rodas traseiras", "Tylne felgi", "Arka jantlar", "Zadní kola" }
S.plate = { "Testo della targa", "Texto da placa", "Tekst tablicy", "Plaka yazısı", "Text SPZ" }
S.fuel = { "Carburante", "Combustível", "Paliwo", "Yakıt", "Palivo" }
S.rust = { "Ruggine", "Ferrugem", "Rdza", "Pas", "Rez" }
S.dirt = { "Sporco", "Sujeira", "Brud", "Kir", "Špína" }
S.steerplay = { "Gioco dello sterzo", "Folga da direção", "Luz kierownicy", "Direksiyon boşluğu", "Vůle řízení" }
S.steeroff = { "Disallineamento sterzo", "Desvio da direção", "Przesunięcie kierownicy", "Direksiyon kayması", "Posun řízení" }
S.handling = { "Aiuto alla guida", "Assistência de direção", "Wspomaganie prowadzenia", "Sürüş yardımı", "Asistent řízení" }

-- people
S.grp_enemies = { "Nemici", "Inimigos", "Wrogowie", "Düşmanlar", "Nepřátelé" }
S.grp_law = { "Legge", "Lei", "Prawo", "Kanun", "Zákon" }
S.grp_allies = { "Alleati", "Aliados", "Sojusznicy", "Müttefikler", "Spojenci" }
S.grp_squad = { "Squadra", "Esquadrão", "Oddział", "Ekip", "Oddíl" }
S.f_marcano = { "Mafia di Marcano", "Máfia do Marcano", "Mafia Marcano", "Marcano mafyası", "Marcanova mafie" }
S.f_italian = { "Italiani", "Italianos", "Włosi", "İtalyanlar", "Italové" }
S.f_dixie = { "Dixie", "Dixie", "Dixie", "Dixie", "Dixie" }
S.f_klan = { "Il Klan", "A Klan", "Klan", "Klan", "Klan" }
S.f_merc = { "Mercenari", "Mercenários", "Najemnicy", "Paralı askerler", "Žoldáci" }
S.f_police = { "Polizia", "Polícia", "Policja", "Polis", "Policie" }
S.f_sheriff = { "Sceriffo", "Xerife", "Szeryf", "Şerif", "Šerif" }
S.f_vito = { "Gli uomini di Vito", "Gente do Vito", "Ludzie Vita", "Vito'nun adamları", "Vitovi lidé" }
S.f_irish = { "Irlandesi di Burke", "Irlandeses do Burke", "Irlandczycy Burke'a", "Burke'ün İrlandalıları", "Burkeovi Irové" }
S.f_haitian = { "Haitiani di Cassandra", "Haitianos da Cassandra", "Haitańczycy Cassandry", "Cassandra'nın Haitilileri",
	"Cassandřini Haiťané" }
S.n_military = { "militari", "militares", "wojsko", "askerler", "armáda" }
S.n_county = { "contea", "condado", "hrabstwo", "ilçe", "okres" }
S.w_pistol = { "Con pistole", "Pistolas", "Z pistoletami", "Tabancalı", "S pistolemi" }
S.w_melee = { "Armi bianche", "Armas brancas", "Z bronią białą", "Kesici silahlı", "Se zbraněmi na blízko" }
S.w_fists = { "A mani nude", "Na mão", "Na pięści", "Yumrukla", "Na pěsti" }
S.w_shotgun = { "Con fucili a pompa", "Escopetas", "Ze strzelbami", "Pompalı", "S brokovnicemi" }
S.w_smg = { "Con mitra", "Submetralhadoras", "Z pistoletami maszynowymi", "Hafif makineli", "Se samopaly" }
S.w_rifle = { "Con fucili", "Fuzis", "Z karabinami", "Tüfekli", "S puškami" }
S.w_sniper = { "Cecchini", "Atiradores de elite", "Snajperzy", "Keskin nişancılar", "Odstřelovači" }
S.w_mixed = { "Misti", "Misturados", "Mieszani", "Karışık", "Smíšené" }
S.faction_d = { "Dentro: quante persone e con quali armi", "Dentro: quantas pessoas e com quais armas",
	"W środku: ile osób i z jaką bronią", "İçinde: kaç kişi ve hangi silahlarla", "Uvnitř: kolik lidí a s jakými zbraněmi" }
S.people_count = { "Quante", "Quantos", "Ile osób", "Kaç kişi", "Kolik" }
S.people_count_d = { "Viene ricordato. 1-4 arrivano in un'auto, 7 in due", "Fica salvo. 1-4 chegam em um carro, 7 em dois",
	"Zapamiętywane. 1-4 przyjeżdżają jednym autem, 7 dwoma", "Hatırlanır. 1-4 kişi bir arabayla, 7 kişi iki arabayla gelir",
	"Zapamatuje se. 1-4 přijedou jedním autem, 7 dvěma" }
S.grp_weapon = { "Armi", "Armas", "Broń", "Silahlar", "Zbraně" }
S.arrive_one = { "Arrivano in un'auto 11 m davanti a te e scendono: %d", "Chegam em um carro 11 m à sua frente e descem: %d",
	"Przyjadą autem 11 m przed tobą i wysiądą: %d os.", "11 m önüne bir arabayla gelip inerler: %d kişi",
	"Přijedou autem 11 m před tebe a vystoupí: %d" }
S.arrive_two = { "Arrivano in due auto 11 m davanti a te e scendono: %d", "Chegam em dois carros 11 m à sua frente e descem: %d",
	"Przyjadą dwoma autami 11 m przed tobą i wysiądą: %d os.", "11 m önüne iki arabayla gelip inerler: %d kişi",
	"Přijedou dvěma auty 11 m před tebe a vystoupí: %d" }
S.clear_squad = { "Rimuovi gli apparsi", "Remover os gerados", "Usuń przywołanych", "Çağrılanları kaldır", "Odstranit přivolané" }
S.clear_squad_d = { "Rimuove tutti quelli fatti apparire dal trainer, auto comprese", "Remove todos que o trainer gerou, com os carros",
	"Usuwa wszystkich przywołanych przez trainer, razem z autami", "Trainer'ın çağırdığı herkesi arabalarıyla birlikte kaldırır",
	"Odstraní všechny, které přivolal trainer, i s auty" }
S.squad_smoke = { "La squadra si accende una sigaretta", "O esquadrão acende um cigarro", "Oddział zapala", "Ekip sigara yakar",
	"Oddíl si zapálí" }
S.squad_smoke_d = { "Le persone apparse si accendono una sigaretta sul posto", "As pessoas geradas acendem um cigarro onde estão",
	"Przywołani ludzie zapalają na miejscu", "Çağrılan kişiler oldukları yerde sigara yakar", "Přivolaní lidé si zapálí na místě" }

-- world
S.grp_time = { "Ora", "Hora", "Czas", "Saat", "Čas" }
S.hour = { "Ora del giorno", "Hora do dia", "Pora dnia", "Günün saati", "Denní doba" }
S.hour_d = { "←→ cambia l'ora subito", "←→ muda a hora na hora", "←→ od razu zmienia godzinę", "←→ saati hemen değiştirir",
	"←→ hned změní hodinu" }
S.flow = { "Velocità dell'orologio", "Velocidade do relógio", "Tempo zegara", "Saat hızı", "Rychlost hodin" }
S.flow_d = { "Quanto velocemente passa il giorno. Il gioco in sé non accelera", "Quão rápido o dia passa. O jogo em si não acelera",
	"Jak szybko mija doba. Sama gra nie przyspiesza", "Günün ne kadar hızlı geçtiği. Oyunun kendisi hızlanmaz",
	"Jak rychle plyne den. Hra samotná se nezrychlí" }
S.exact = { "Ora esatta…", "Hora exata…", "Dokładny czas…", "Tam saat…", "Přesný čas…" }
S.exact_prompt = { "Ora da 0 a 23, decimali ammessi: 18.5 = 18:30", "Hora de 0 a 23, decimais permitidos: 18.5 = 18:30",
	"Godzina od 0 do 23, można z ułamkiem: 18.5 = 18:30", "0 ile 23 arası saat, ondalık olabilir: 18.5 = 18:30",
	"Hodina 0 až 23, lze i desetinně: 18.5 = 18:30" }
S.weather = { "Meteo", "Clima", "Pogoda", "Hava", "Počasí" }
S.weather_d = { "Qualsiasi meteo del gioco", "Qualquer clima do jogo", "Dowolna pogoda z gry", "Oyundaki herhangi bir hava durumu",
	"Jakékoli počasí ze hry" }
S.grp_traffic = { "Traffico", "Trânsito", "Ruch uliczny", "Trafik", "Provoz" }
S.density = { "Densità", "Densidade", "Gęstość", "Yoğunluk", "Hustota" }
S.t0 = { "vuoto", "vazio", "pusto", "boş", "prázdno" }
S.t05 = { "scarso", "pouco", "rzadko", "seyrek", "řídce" }
S.t1 = { "normale", "normal", "normalnie", "normal", "normálně" }
S.t15 = { "denso", "denso", "gęsto", "yoğun", "hustě" }
S.t2 = { "massimo", "máximo", "maksimum", "azami", "maximum" }
S.traffic_status = { "Ora x%.1f, traffico %s", "Agora x%.1f, trânsito %s", "Teraz x%.1f, ruch %s", "Şu an x%.1f, trafik %s",
	"Teď x%.1f, provoz %s" }
S.grp_police = { "Polizia", "Polícia", "Policja", "Polis", "Policie" }
S.clear_wanted = { "Togli il livello di ricercato", "Limpar procurado", "Usuń poszukiwanie", "Aranma seviyesini kaldır",
	"Zrušit pátrání" }
S.wanted = { "Livello di ricercato", "Nível de procurado", "Poziom poszukiwania", "Aranma seviyesi", "Úroveň pátrání" }
S.wanted_d = { "La polizia inizia la caccia al livello scelto", "A polícia começa a caçada no nível escolhido",
	"Policja zacznie obławę na wybranym poziomie", "Polis seçilen seviyede ava başlar", "Policie začne honičku na zvolené úrovni" }
S.wanted_hold = { "Il ricercato non scende", "O procurado não cai", "Poszukiwanie nie spada", "Aranma düşmez", "Pátrání neklesá" }
S.nooffence = { "Reati ignorati", "Infrações ignoradas", "Wykroczenia ignorowane", "Suçlar görmezden gelinir", "Přestupky ignorovány" }
S.nooffence_d = { "La polizia ignora i nuovi reati ma resta in città", "A polícia ignora novas infrações, mas continua na cidade",
	"Policja ignoruje nowe wykroczenia, ale zostaje w mieście", "Polis yeni suçları görmezden gelir ama şehirde kalır",
	"Policie ignoruje nové přestupky, ale zůstává ve městě" }
S.nodispatch = { "Niente radio della polizia", "Sem rádio da polícia", "Bez policyjnego radia", "Polis telsizi yok",
	"Bez policejní vysílačky" }
S.police_off = { "Polizia disattivata", "Polícia desligada", "Policja wyłączona", "Polis kapalı", "Policie vypnuta" }
S.grp_misc = { "Altro", "Outros", "Inne", "Diğer", "Ostatní" }
S.water = { "Acqua visibile", "Água visível", "Woda widoczna", "Su görünür", "Voda viditelná" }
S.clearweap = { "Togli le armi a terra", "Remover armas do chão", "Usuń broń z ziemi", "Yerdeki silahları kaldır",
	"Odstranit zbraně ze země" }
S.clearweap_d = { "Entro 20 m", "Num raio de 20 m", "W promieniu 20 m", "20 m çevrede", "V okruhu 20 m" }
S.corpses = { "Conta i corpi vicini", "Contar corpos por perto", "Policz ciała w pobliżu", "Yakındaki cesetleri say",
	"Spočítat těla poblíž" }
S.corpses_d = { "Entro 100 m", "Num raio de 100 m", "W promieniu 100 m", "100 m çevrede", "V okruhu 100 m" }

-- camera
S.eyecam = { "Visuale in prima persona", "Visão em primeira pessoa", "Widok z pierwszej osoby", "Birinci şahıs görünümü",
	"Pohled z první osoby" }
S.eyecam_d = { "Telecamera negli occhi dell'eroe: mani e arma in vista, a piedi e alla guida",
	"Câmera nos olhos do herói: mãos e arma à vista, a pé e ao volante",
	"Kamera w oczach bohatera: widać ręce i broń, pieszo i za kierownicą",
	"Kamera kahramanın gözlerinde: eller ve silah görünür, yürürken ve direksiyonda",
	"Kamera v očích hrdiny: ruce a zbraň na očích, pěšky i za volantem" }
S.fps_quick_d = { "Invio attiva/disattiva (attiva di base, la scelta viene ricordata). Tutte le impostazioni nel sottomenu sotto",
	"Enter liga/desliga (ligado por padrão, a escolha fica salva). Todas as configurações no submenu abaixo",
	"Enter włącza/wyłącza (domyślnie włączony, wybór jest zapamiętywany). Pełne ustawienia w podmenu poniżej",
	"Enter açar/kapatır (varsayılan açık, seçim hatırlanır). Tüm ayarlar aşağıdaki alt menüde",
	"Enter zapne/vypne (výchozí zapnuto, volba se pamatuje). Všechna nastavení v podnabídce níže" }
S.fps_submenu = { "Impostazioni prima persona…", "Configurações de primeira pessoa…", "Ustawienia widoku z pierwszej osoby…",
	"Birinci şahıs ayarları…", "Nastavení pohledu z první osoby…" }
S.fps_on = { "Prima persona attiva", "Primeira pessoa ligada", "Widok z pierwszej osoby włączony", "Birinci şahıs açık",
	"Pohled z první osoby zapnut" }
S.fps_off = { "Prima persona disattivata", "Primeira pessoa desligada", "Widok z pierwszej osoby wyłączony", "Birinci şahıs kapalı",
	"Pohled z první osoby vypnut" }
S.freecam = { "Telecamera libera", "Câmera livre", "Wolna kamera", "Serbest kamera", "Volná kamera" }
S.freecam_d = { "Finché è attiva, il gioco è fermo", "Enquanto ligada, o jogo fica parado", "Gdy jest włączona, gra stoi",
	"Açıkken oyun durur", "Dokud je zapnutá, hra stojí" }
S.camreset = { "Ripristina telecamera", "Redefinir câmera", "Zresetuj kamerę", "Kamerayı sıfırla", "Obnovit kameru" }

-- settings
S.language = { "Lingua", "Idioma", "Język", "Dil", "Jazyk" }
S.language_d = { "Cambia la lingua di tutto il trainer", "Muda o idioma de todo o trainer", "Zmienia język całego trainera",
	"Tüm trainer'ın dilini değiştirir", "Změní jazyk celého traineru" }
S.theme = { "Tema", "Tema", "Motyw", "Tema", "Motiv" }
S.theme_d = { "Pannello scuro o chiaro. Cambia subito", "Painel escuro ou claro. Muda na hora", "Ciemny lub jasny panel. Zmienia się od razu",
	"Koyu veya açık panel. Hemen değişir", "Tmavý nebo světlý panel. Změní se hned" }
S.theme_dark = { "Scuro", "Escuro", "Ciemny", "Koyu", "Tmavý" }
S.theme_light = { "Chiaro", "Claro", "Jasny", "Açık", "Světlý" }
S.transparency = { "Trasparenza", "Transparência", "Przezroczystość", "Saydamlık", "Průhlednost" }
S.transparency_d = { "Quanto del gioco sfocato si vede attraverso il pannello e gli avvisi. Nessuna: pannello pieno, senza sfocatura. Più è alta, più si vede il gioco e più sbiadisce il testo piccolo su un cielo chiaro. Cambia subito",
	"Quanto do jogo desfocado aparece através do painel e dos avisos. Nenhuma: painel sólido, sem desfoque. Quanto maior, mais do jogo aparece e mais fraco fica o texto pequeno sobre um céu claro. Muda na hora",
	"Ile rozmytej gry widać przez panel i powiadomienia. Brak: pełny panel bez rozmycia. Im wyżej, tym więcej widać grę, a drobny tekst na jasnym niebie blednie. Zmienia się od razu",
	"Panel ve bildirimlerin arkasından bulanık oyunun ne kadar göründüğü. Yok: bulanıklıksız düz panel. Ne kadar yüksekse oyun o kadar görünür ve açık gökyüzünde küçük yazı o kadar soluklaşır. Hemen değişir",
	"Kolik rozmazané hry je vidět přes panel a oznámení. Žádná: plný panel bez rozmazání. Čím výš, tím víc je vidět hra a drobný text na jasné obloze bledne. Změní se hned" }
S.glass_none = { "Nessuna", "Nenhuma", "Brak", "Yok", "Žádná" }
S.glass_low = { "Bassa", "Baixa", "Niska", "Düşük", "Nízká" }
S.glass_medium = { "Media", "Média", "Średnia", "Orta", "Střední" }
S.glass_high = { "Alta", "Alta", "Wysoka", "Yüksek", "Vysoká" }
S.glass_max = { "Massima", "Máxima", "Maksymalna", "Azami", "Maximální" }
S.ui_scale = { "Dimensione dell'interfaccia", "Tamanho da interface", "Rozmiar interfejsu", "Arayüz boyutu", "Velikost rozhraní" }
S.ui_scale_d = { "Menu e avvisi più grandi o più piccoli. Cambia subito", "Menu e avisos maiores ou menores. Muda na hora",
	"Większe lub mniejsze menu i powiadomienia. Zmienia się od razu", "Menü ve bildirimleri büyütür veya küçültür. Hemen değişir",
	"Větší nebo menší nabídka a oznámení. Změní se hned" }
S.panel_side = { "Pannello", "Painel", "Panel", "Panel", "Panel" }
S.panel_side_d = { "Da quale lato dello schermo si apre il menu", "Em que lado da tela o menu abre", "Po której stronie ekranu otwiera się menu",
	"Menünün ekranın hangi tarafında açıldığı", "Na které straně obrazovky se nabídka otevírá" }
S.side_left = { "Sinistra", "Esquerda", "Z lewej", "Sol", "Vlevo" }
S.side_right = { "Destra", "Direita", "Z prawej", "Sağ", "Vpravo" }
S.motion = { "Animazione", "Animação", "Animacja", "Animasyon", "Animace" }
S.motion_d = { "Ridotta: menu e avvisi appaiono senza scorrere, la selezione salta subito",
	"Reduzida: o menu e os avisos aparecem sem deslizar, a seleção pula na hora",
	"Mniej: menu i powiadomienia pojawiają się bez przesuwania, zaznaczenie przeskakuje od razu",
	"Azaltılmış: menü ve bildirimler kaymadan belirir, seçim hemen atlar",
	"Méně: nabídka a oznámení se objeví bez posunu, výběr přeskočí hned" }
S.motion_full = { "Completa", "Completa", "Pełna", "Tam", "Plná" }
S.motion_reduced = { "Ridotta", "Reduzida", "Mniej", "Azaltılmış", "Méně" }
S.theme_need_asi = { "Tema salvato; si applica con il nuovo ASI (BUILD_STREET_FIGHT_ASI.bat)",
	"Tema salvo; aplica com o ASI novo (BUILD_STREET_FIGHT_ASI.bat)",
	"Motyw zapisany; zadziała z nowym ASI (BUILD_STREET_FIGHT_ASI.bat)",
	"Tema kaydedildi; yeni ASI ile uygulanır (BUILD_STREET_FIGHT_ASI.bat)",
	"Motiv uložen; použije se s novým ASI (BUILD_STREET_FIGHT_ASI.bat)" }
S.selftest = { "Autotest", "Autoteste", "Autotest", "Öz denetim", "Autotest" }
S.selftest_d = { "«Controlla tutto» e un rapporto su ogni voce del trainer: ci sono le sue funzioni del gioco, e una prova di ciò che si può rimettere subito. Ciò che non funziona è in grigio, non rimosso",
	"“Verificar tudo” e um relatório de cada item do trainer: se as funções do jogo existem, e um teste do que dá para desfazer na hora. O que não funciona fica cinza, não é removido",
	"„Sprawdź wszystko” i raport o każdej pozycji trainera: czy gra ma jej funkcje, i próba tego, co da się od razu cofnąć. Co nie działa, jest wyszarzone, nie usunięte",
	"“Her şeyi kontrol et” ve trainer'ın her satırı için bir rapor: oyunun gerekli işlevleri var mı ve hemen geri alınabilenlerin bir denemesi. Çalışmayanlar gri olur, kaldırılmaz",
	"„Zkontrolovat vše“ a zpráva o každé položce traineru: zda má hra její funkce, a zkouška toho, co lze hned vrátit. Co nefunguje, je zašedlé, ne odebrané" }

-- notices
S.on = { "attivo", "ligado", "włączone", "açık", "zapnuto" }
S.off = { "disattivato", "desligado", "wyłączone", "kapalı", "vypnuto" }
S.state_fmt = { "%s: %s", "%s: %s", "%s: %s", "%s: %s", "%s: %s" }
S.done_fmt = { "%s: fatto", "%s: feito", "%s: gotowe", "%s: tamam", "%s: hotovo" }
S.failed = { "%s non riuscito: %s", "%s falhou: %s", "%s nie powiodło się: %s", "%s başarısız: %s", "%s selhalo: %s" }
S.action = { "azione", "ação", "akcja", "işlem", "akce" }
S.need_trainer = { "richiede la mod trainer (ScriptHook\\lua\\trainer)", "requer o mod trainer (ScriptHook\\lua\\trainer)",
	"wymaga moda trainer (ScriptHook\\lua\\trainer)", "trainer modu gerekli (ScriptHook\\lua\\trainer)",
	"vyžaduje mod trainer (ScriptHook\\lua\\trainer)" }
S.no_player = { "nessun giocatore. Aprilo nel mondo, non in un menu o in un filmato",
	"sem jogador. Abra isto no mundo, não em um menu ou cena",
	"brak gracza. Otwórz to w świecie gry, nie w menu ani przerywniku",
	"oyuncu yok. Bunu menüde veya ara sahnede değil, oyun dünyasında aç",
	"žádný hráč. Otevři to ve světě, ne v nabídce ani v cutscéně" }
S.healed_n = { "salute ripristinata: %d su %d", "vida restaurada: %d de %d", "zdrowie przywrócone: %d z %d",
	"sağlık yenilendi: %d / %d", "zdraví obnoveno: %d z %d" }
S.healed = { "salute ripristinata", "vida restaurada", "zdrowie przywrócone", "sağlık yenilendi", "zdraví obnoveno" }
S.not_in_car = { "non sei in auto", "você não está em um carro", "nie jesteś w aucie", "arabada değilsin", "nejsi v autě" }
S.repaired = { "auto riparata", "carro consertado", "auto naprawione", "araba onarıldı", "auto opraveno" }
S.ammo_n = { "munizioni ricaricate, arma in mano: %d (prima %d)", "munição recarregada, arma na mão: %d (antes %d)",
	"amunicja uzupełniona, broń w ręku: %d (było %d)", "mermi dolduruldu, eldeki silah: %d (önce %d)",
	"náboje doplněny, zbraň v ruce: %d (bylo %d)" }
S.ammo_ok = { "munizioni ricaricate", "munição recarregada", "amunicja uzupełniona", "mermi dolduruldu", "náboje doplněny" }
S.wanted_cleared = { "ricercato tolto, cala di nuovo normalmente", "procurado removido, volta a cair normalmente",
	"poszukiwanie zdjęte, znowu wygasa normalnie", "aranma kaldırıldı, yine normal şekilde azalır",
	"pátrání zrušeno, opět normálně slábne" }
S.wanted_set = { "ricercato: %d", "procurado: %d", "poszukiwanie: %d", "aranma: %d", "pátrání: %d" }
S.time_ok = { "l'orologio segna %d:%02d", "o relógio marca %d:%02d", "zegar pokazuje %d:%02d", "saat %d:%02d gösteriyor",
	"hodiny ukazují %d:%02d" }
S.time_refused = { "il gioco ha tenuto l'ora %.1f, prova fuori da una missione", "o jogo manteve a hora %.1f, tente fora de uma missão",
	"gra zostawiła godzinę %.1f, spróbuj poza misją", "oyun saati %.1f olarak tuttu, görev dışında dene",
	"hra ponechala čas %.1f, zkus to mimo misi" }
S.time_bad = { "serve un numero da 0 a 23", "é preciso um número de 0 a 23", "potrzebna liczba od 0 do 23",
	"0 ile 23 arası bir sayı gerekli", "je potřeba číslo od 0 do 23" }
S.god_on_ok = { "invincibilità attiva e verificata: nessun danno passa", "modo deus ligado e verificado: nenhum dano passa",
	"nieśmiertelność włączona i sprawdzona: obrażenia nie przechodzą", "ölümsüzlük açık ve doğrulandı: hasar geçmiyor",
	"nesmrtelnost zapnuta a ověřena: poškození neprojde" }
S.god_on_unk = { "invincibilità attiva (il gioco non riporta lo stato)", "modo deus ligado (o jogo não informa o estado)",
	"nieśmiertelność włączona (gra nie zwraca stanu)", "ölümsüzlük açık (oyun durumu bildirmiyor)",
	"nesmrtelnost zapnuta (hra nehlásí stav)" }
S.god_off = { "invincibilità disattivata", "modo deus desligado", "nieśmiertelność wyłączona", "ölümsüzlük kapalı", "nesmrtelnost vypnuta" }
S.god_refused = { "il gioco ha rifiutato l'invincibilità, ora %s", "o jogo recusou o modo deus, agora %s",
	"gra odrzuciła nieśmiertelność, teraz %s", "oyun ölümsüzlüğü reddetti, şimdi %s", "hra nesmrtelnost odmítla, teď %s" }
S.car_fail = { "richiesta del veicolo fallita: %s", "o pedido do veículo falhou: %s", "pojazd się nie pojawił: %s",
	"araç isteği başarısız: %s", "vozidlo se nepodařilo: %s" }
S.car_timeout = { "%s non si è caricata in 30 secondi", "%s não carregou em 30 segundos", "%s nie wczytało się w 30 sekund",
	"%s 30 saniyede yüklenmedi", "%s se nenačetlo za 30 sekund" }
S.player_gone = { "il giocatore è sparito durante il caricamento", "o jogador sumiu durante o carregamento",
	"gracz zniknął podczas wczytywania", "yükleme sırasında oyuncu kayboldu", "hráč zmizel během načítání" }
S.no_entity = { "il gioco non ha restituito il veicolo", "o jogo não devolveu o veículo", "gra nie zwróciła pojazdu",
	"oyun aracı döndürmedi", "hra nevrátila vozidlo" }
S.ahead = { "davanti: %s", "à frente: %s", "przed tobą: %s", "önünde: %s", "před tebou: %s" }
S.traffic_empty = { "strade vuote: niente auto nuove, quelle in giro finiscono il percorso",
	"ruas vazias: sem carros novos, os que já rodam terminam o trajeto",
	"puste ulice: nowe auta się nie pojawiają, jadące dojadą",
	"boş sokaklar: yeni araba çıkmaz, yoldakiler rotasını bitirir",
	"prázdné ulice: nová auta nepřibudou, jedoucí dojedou" }
S.traffic_more = { "densità x%.1f, limite auto %d; le nuove arrivano in 20-60 secondi",
	"densidade x%.1f, limite de carros %d; novos chegam em 20-60 segundos",
	"gęstość x%.1f, limit aut %d; nowe przyjadą w 20-60 sekund",
	"yoğunluk x%.1f, araba sınırı %d; yeniler 20-60 saniyede gelir",
	"hustota x%.1f, limit aut %d; nová přijedou za 20-60 sekund" }
S.traffic_set = { "densità x%.1f", "densidade x%.1f", "gęstość x%.1f", "yoğunluk x%.1f", "hustota x%.1f" }
S.traffic_noapi = { "la densità non cambia: serve uno ScriptHook più recente", "a densidade não muda: é preciso um ScriptHook mais novo",
	"gęstość się nie zmienia: potrzebny nowszy ScriptHook", "yoğunluk değişmiyor: daha yeni bir ScriptHook gerekli",
	"hustota se nemění: je potřeba novější ScriptHook" }
S.traffic_refused = { "il gioco non ha permesso di cambiare la densità", "o jogo não deixou mudar a densidade",
	"gra nie pozwoliła zmienić gęstości", "oyun yoğunluğu değiştirmeye izin vermedi", "hra nedovolila změnit hustotu" }
S.flow_set = { "l'orologio va x%d", "o relógio anda x%d", "zegar idzie x%d", "saat x%d hızında", "hodiny jdou x%d" }
S.squad_busy = { "una squadra sta ancora arrivando, aspetta", "um esquadrão ainda está chegando, espere",
	"oddział jeszcze dojeżdża, poczekaj", "bir ekip hâlâ geliyor, bekle", "oddíl ještě přijíždí, počkej" }
S.squad_coming = { "%s: %s ×%d, in arrivo", "%s: %s ×%d, a caminho", "%s: %s ×%d, już jadą", "%s: %s ×%d, yolda",
	"%s: %s ×%d, už jedou" }
S.squad_none = { "%s: nessuno piazzato, %s", "%s: ninguém posicionado, %s", "%s: nikogo nie postawiono, %s",
	"%s: kimse yerleştirilmedi, %s", "%s: nikdo nebyl umístěn, %s" }
S.squad_partial = { "%s: %d sul posto, seconda auto: %s", "%s: %d no local, segundo carro: %s", "%s: na miejscu %d, drugie auto: %s",
	"%s: yerinde %d, ikinci araba: %s", "%s: na místě %d, druhé auto: %s" }
S.squad_ok = { "%s: %d sul posto, scendono dalle auto", "%s: %d no local, descendo dos carros", "%s: na miejscu %d, wysiadają z aut",
	"%s: yerinde %d, arabalardan iniyorlar", "%s: na místě %d, vystupují z aut" }
S.err_refused = { "il gioco ha rifiutato la richiesta", "o jogo recusou o pedido", "gra odrzuciła żądanie", "oyun isteği reddetti",
	"hra požadavek odmítla" }
S.err_models = { "i modelli non si sono caricati in 30 secondi", "os modelos não carregaram em 30 segundos",
	"modele nie wczytały się w 30 sekund", "modeller 30 saniyede yüklenmedi", "modely se nenačetly za 30 sekund" }
S.err_nocar = { "impossibile piazzare l'auto: %s", "não deu para posicionar o carro: %s", "nie udało się postawić auta: %s",
	"araba yerleştirilemedi: %s", "auto nešlo umístit: %s" }
S.err_noappear = { "l'auto della squadra non è apparsa", "o carro do esquadrão não apareceu", "auto z oddziałem się nie pojawiło",
	"ekip arabası belirmedi", "auto s oddílem se neobjevilo" }
S.err_nopeople = { "il gioco non ha restituito nessuno", "o jogo não devolveu ninguém", "gra nie zwróciła ludzi", "oyun kimseyi döndürmedi",
	"hra nevrátila nikoho" }
S.removed = { "auto delle squadre rimosse: %d", "carros de esquadrão removidos: %d", "usunięto auta z oddziałami: %d",
	"kaldırılan ekip arabası: %d", "odstraněno aut s oddíly: %d" }
S.smoke_in_car = { "scendi dall'auto per fumare", "saia do carro para fumar", "wysiądź z auta, żeby zapalić",
	"sigara içmek için arabadan in", "vystup z auta, abys mohl kouřit" }
S.smoke_busy = { "Lincoln sta ancora fumando. «Basta» lo interrompe", "Lincoln ainda está fumando. “Parar” interrompe",
	"Lincoln jeszcze pali. „Wystarczy” przerwie", "Lincoln hâlâ sigara içiyor. “Yeter” keser", "Lincoln ještě kouří. „Dost“ to přeruší" }
S.smoke_none_known = { "il gioco non dà a Lincoln animazioni di fumo (verificato), vedi ScriptHook.log",
	"o jogo não dá animações de fumar ao Lincoln (verificado), veja ScriptHook.log",
	"gra nie daje Lincolnowi animacji palenia (sprawdzone), szczegóły w ScriptHook.log",
	"oyun Lincoln'e sigara animasyonu vermiyor (kontrol edildi), ayrıntılar ScriptHook.log'da",
	"hra Lincolnovi nedává animace kouření (ověřeno), podrobnosti v ScriptHook.log" }
S.smoke_scripted = { "ora il gioco controlla Lincoln (scena o missione), niente fumo",
	"o jogo está controlando o Lincoln agora (cena ou missão), não dá para fumar",
	"teraz Lincolnem steruje gra (scena lub misja), zapalić się nie da",
	"şu an Lincoln'ü oyun kontrol ediyor (sahne veya görev), sigara içilemez",
	"teď Lincolna ovládá hra (scéna nebo mise), kouřit nejde" }
S.smoke_probing = { "cerco un'animazione che il gioco concede a Lincoln (fino a 11 s, «Basta» interrompe)",
	"procurando uma animação que o jogo permita ao Lincoln (até 11 s, “Parar” interrompe)",
	"szukam animacji, którą gra da Lincolnowi (do 11 s, „Wystarczy” przerwie)",
	"oyunun Lincoln'e izin verdiği bir animasyon aranıyor (11 sn'ye kadar, “Yeter” keser)",
	"hledám animaci, kterou hra Lincolnovi dovolí (až 11 s, „Dost“ přeruší)" }
S.smoked_puff = { "ha fatto un tiro", "deu uma tragada", "zaciągnął się", "bir nefes çekti", "potáhl si" }
S.smoked_stand = { "ha fumato", "fumou", "zapalił", "sigara içti", "zakouřil si" }
S.smoked_sit = { "si è seduto a fumare", "sentou e fumou", "usiadł i zapalił", "oturup sigara içti", "sedl si a zakouřil" }
S.smoke_nolock = { "il gioco non ha liberato Lincoln per l'animazione", "o jogo não liberou o Lincoln para a animação",
	"gra nie zwolniła Lincolna do animacji", "oyun Lincoln'ü animasyon için serbest bırakmadı", "hra neuvolnila Lincolna pro animaci" }
S.smoke_nosit = { "Lincoln non ha l'animazione per fumare seduto", "Lincoln não tem animação de sentar e fumar no jogo",
	"Lincoln nie ma w grze animacji palenia na siedząco", "Lincoln'ün oyunda oturup sigara içme animasyonu yok",
	"Lincoln nemá ve hře animaci kouření vsedě" }
S.smoke_nosmoke = { "Lincoln non ha animazioni di fumo: tutte le varianti rifiutate. Niente più posa a T",
	"As animações do Lincoln não têm fumo: todas as variantes recusadas. Chega de pose em T",
	"Lincoln nie ma animacji palenia: gra odrzuciła wszystkie warianty. T-pozy już nie będzie",
	"Lincoln'ün animasyonlarında sigara yok: tüm varyantlar reddedildi. Artık T-pozu yok",
	"Lincoln nemá animace kouření: hra odmítla všechny varianty. T-póza už nebude" }
S.smoke_unknown = { "il gioco non ha riprodotto l'animazione, vedi ScriptHook.log", "o jogo não reproduziu a animação, veja ScriptHook.log",
	"gra nie odtworzyła animacji, szczegóły w ScriptHook.log", "oyun animasyonu oynatmadı, ayrıntılar ScriptHook.log'da",
	"hra animaci nepřehrála, podrobnosti v ScriptHook.log" }
S.smoke_stopped = { "ha smesso di fumare, comandi restituiti", "parou de fumar, controle devolvido", "przestał palić, sterowanie wróciło",
	"sigarayı bıraktı, kontrol geri geldi", "přestal kouřit, ovládání se vrátilo" }
S.squad_first = { "prima fai apparire delle persone: Persone → squadra", "gere pessoas primeiro: Pessoas → esquadrão",
	"najpierw przywołaj ludzi: Ludzie → oddział", "önce insan çağır: İnsanlar → ekip", "nejdřív přivolej lidi: Lidé → oddíl" }
S.squad_smoking = { "fumano: %d", "fumando: %d", "zapalili: %d", "sigara yaktı: %d", "zapálili si: %d" }
S.squad_nosmoke = { "il gioco non li ha fatti fumare, vedi ScriptHook.log", "o jogo não deixou eles fumarem, veja ScriptHook.log",
	"gra nie pozwoliła im zapalić, szczegóły w ScriptHook.log", "oyun onların sigara içmesine izin vermedi, ayrıntılar ScriptHook.log'da",
	"hra jim nedovolila zapálit, podrobnosti v ScriptHook.log" }
S.test_ok = { "controllo: tutto a posto, %d su %d", "verificação: tudo certo, %d de %d", "test: wszystko w porządku, %d z %d",
	"kontrol: her şey yolunda, %d / %d", "test: vše v pořádku, %d z %d" }
S.test_bad = { "controllo: %d su %d a posto. Guasti: %s", "verificação: %d de %d ok. Com defeito: %s",
	"test: %d z %d w porządku. Nie działa: %s", "kontrol: %d / %d sorunsuz. Bozuk: %s", "test: %d z %d v pořádku. Nefunguje: %s" }
S.test_smoke_no = { "fumo: il gioco non ha animazioni di fumo per Lincoln", "fumar: o jogo não tem animações de fumar para o Lincoln",
	"palenie: gra nie ma animacji palenia dla Lincolna", "sigara: oyunda Lincoln için sigara animasyonu yok",
	"kouření: hra nemá pro Lincolna animace kouření" }
S.test_smoke_ok = { "fumo: funziona, variante «%s»", "fumar: funciona, variante “%s”", "palenie: działa, wariant „%s”",
	"sigara: çalışıyor, varyant “%s”", "kouření: funguje, varianta „%s“" }

-- self-check (checks.lua)
S.chk_ok = { "funziona", "funciona", "działa", "çalışıyor", "funguje" }
S.chk_fail = { "non funziona", "não funciona", "nie działa", "çalışmıyor", "nefunguje" }
S.chk_off = { "disattivato", "desligado", "wyłączone", "kapalı", "vypnuto" }
S.chk_skip = { "non controllato", "não verificado", "niesprawdzone", "kontrol edilmedi", "nezkontrolováno" }
S.chk_wait = { "controllo…", "verificando…", "sprawdzanie…", "kontrol ediliyor…", "kontroluje se…" }
S.chk_wait_d = { "Aspetta la risposta del gioco; la riga si aggiorna da sola", "Espera a resposta do jogo; a linha se atualiza sozinha",
	"Czeka na odpowiedź gry; wiersz odświeży się sam", "Oyunun yanıtını bekliyor; satır kendini günceller",
	"Čeká na odpověď hry; řádek se obnoví sám" }
S.chk_run = { "Controlla tutto", "Verificar tudo", "Sprawdź wszystko", "Her şeyi kontrol et", "Zkontrolovat vše" }
S.chk_run_d = { "Prova ogni voce del trainer. Invincibilità, ora del giorno e salute cambiano per un attimo e tornano subito. Un paio di secondi; le righe sotto si aggiornano da sole",
	"Testa cada item do trainer. Modo deus, hora do dia e vida mudam por um instante e voltam na hora. Alguns segundos; as linhas abaixo se atualizam sozinhas",
	"Próbuje każdej pozycji trainera. Nieśmiertelność, pora dnia i zdrowie zmieniają się na chwilę i od razu wracają. Kilka sekund; wiersze poniżej odświeżą się same",
	"Trainer'ın her satırını dener. Ölümsüzlük, günün saati ve sağlık bir an değişir ve hemen geri döner. Birkaç saniye; aşağıdaki satırlar kendini günceller",
	"Vyzkouší každou položku traineru. Nesmrtelnost, denní doba a zdraví se na okamžik změní a hned vrátí. Pár sekund; řádky níže se obnoví samy" }
S.chk_never = { "Non ancora controllato — premi «Controlla tutto»", "Ainda não verificado — aperte “Verificar tudo”",
	"Jeszcze nie sprawdzano — naciśnij „Sprawdź wszystko”", "Henüz kontrol edilmedi — “Her şeyi kontrol et”e bas",
	"Ještě nezkontrolováno — stiskni „Zkontrolovat vše“" }
S.chk_press_d = { "Premi «Controlla tutto» in alto", "Aperte “Verificar tudo” no topo", "Naciśnij „Sprawdź wszystko” na górze",
	"En üstteki “Her şeyi kontrol et”e bas", "Nahoře stiskni „Zkontrolovat vše“" }
S.chk_running = { "il controllo è già in corso", "a verificação já está em andamento", "sprawdzanie już trwa", "kontrol zaten sürüyor",
	"kontrola už běží" }
S.chk_summary_fmt = { "Funzionano %d su %d · guasti %d · disattivati %d · non controllati %d",
	"Funcionando %d de %d · com defeito %d · desligados %d · não verificados %d",
	"Działa %d z %d · nie działa %d · wyłączone %d · niesprawdzone %d",
	"Çalışan %d / %d · bozuk %d · kapalı %d · kontrol edilmemiş %d",
	"Funguje %d z %d · nefunguje %d · vypnuto %d · nezkontrolováno %d" }
S.chk_need = { "Al gioco manca: %s", "Falta no jogo: %s", "Brak funkcji gry: %s", "Oyunda eksik: %s", "Hře chybí: %s" }
S.chk_unloaded = { "Il file del trainer %s non si è caricato: il gioco ha rifiutato il suo codice (ScriptHook.log: include() LOAD ERROR)",
	"O arquivo do trainer %s não carregou: o jogo recusou o código (ScriptHook.log: include() LOAD ERROR)",
	"Plik trainera %s się nie wczytał: gra odrzuciła jego kod (ScriptHook.log: include() LOAD ERROR)",
	"Trainer dosyası %s yüklenmedi: oyun kodunu reddetti (ScriptHook.log: include() LOAD ERROR)",
	"Soubor traineru %s se nenačetl: hra odmítla jeho kód (ScriptHook.log: include() LOAD ERROR)" }
S.chk_needs_ok = { "Ci sono tutte le funzioni del gioco che servono (%d)", "Todas as funções do jogo necessárias estão lá (%d)",
	"Wszystkie potrzebne funkcje gry są na miejscu (%d)", "Gereken tüm oyun işlevleri mevcut (%d)",
	"Všechny potřebné funkce hry jsou na místě (%d)" }
S.chk_no_car = { "Serve un'auto: sali e controlla di nuovo", "Precisa de um carro: entre e verifique de novo",
	"Potrzebne auto: wsiądź i sprawdź jeszcze raz", "Araba gerekli: bin ve tekrar kontrol et",
	"Je potřeba auto: nastup a zkontroluj znovu" }
S.chk_no_threads = { "Senza i thread del gioco questo controllo non si può fare", "Sem as threads do jogo esta verificação não roda",
	"Bez wątków gry tego testu nie da się przeprowadzić", "Oyunun iş parçacıkları olmadan bu kontrol yapılamaz",
	"Bez vláken hry tuto kontrolu nelze provést" }
S.chk_grp_base = { "Base", "Base", "Podstawa", "Temel", "Základ" }
S.chk_notify = { "Avvisi", "Avisos", "Powiadomienia", "Bildirimler", "Oznámení" }
S.chk_threads = { "Thread e attesa", "Threads e espera", "Wątki i oczekiwanie", "İş parçacıkları ve bekleme", "Vlákna a čekání" }
S.chk_menu_api = { "Menu: righe dal vivo", "Menu: linhas ao vivo", "Menu: odświeżanie wierszy", "Menü: canlı satırlar",
	"Nabídka: obnova řádků" }
S.chk_text_input = { "Inserimento testo", "Entrada de texto", "Okno wpisywania", "Metin girişi", "Zadávání textu" }
S.chk_settings = { "Salvataggio impostazioni (ScriptHook.ini)", "Salvar configurações (ScriptHook.ini)", "Zapis ustawień (ScriptHook.ini)",
	"Ayarları kaydetme (ScriptHook.ini)", "Ukládání nastavení (ScriptHook.ini)" }
S.chk_settings_d = { "Scritto e riletto", "Gravado e lido de volta", "Zapisane i odczytane z powrotem", "Yazıldı ve geri okundu",
	"Zapsáno a přečteno zpět" }
S.chk_input_aim = { "Tasto di mira (ASI)", "Botão de mira (ASI)", "Przycisk celowania (ASI)", "Nişan tuşu (ASI)", "Tlačítko míření (ASI)" }
S.chk_input_aim_d = { "Serve per la telecamera con l'arma in prima persona", "Necessário para a câmera com arma em primeira pessoa",
	"Potrzebny do kamery z bronią w widoku z pierwszej osoby", "Birinci şahısta silahlı kamera için gerekli",
	"Potřeba pro kameru se zbraní v pohledu z první osoby" }
S.chk_brawl_off = { "Disattivato per ora: non funziona ancora bene", "Desligado por enquanto: ainda não funciona direito",
	"Na razie wyłączone: jeszcze nie działa poprawnie", "Şimdilik kapalı: henüz düzgün çalışmıyor",
	"Zatím vypnuto: ještě nefunguje správně" }
S.chk_input_q = { "Q premuto (ASI)", "Q pressionado (ASI)", "Naciśnięcie Q (ASI)", "Q basıldı (ASI)", "Stisk Q (ASI)" }
S.chk_input_q_d = { "Serve per le eliminazioni in prima persona: i comandi bloccati subito dopo Q sono un'eliminazione, non una scena",
	"Necessário para eliminações em primeira pessoa: os controles travando logo após o Q são uma eliminação, não uma cena",
	"Potrzebne do eliminacji z pierwszej osoby: blokada sterowania tuż po Q to eliminacja, a nie scena",
	"Birinci şahıs infazlar için gerekli: Q'dan hemen sonra kilitlenen kontroller bir infazdır, sahne değil",
	"Potřeba pro likvidace z první osoby: zamčení ovládání hned po Q je likvidace, ne scéna" }
S.chk_input_keys = { "Tasti visuale (ASI)", "Teclas de visão (ASI)", "Klawisze widoku (ASI)", "Görünüm tuşları (ASI)",
	"Klávesy pohledu (ASI)" }
S.chk_input_keys_d = { "Serve per il tasto visuale (prima / terza persona) e per guardare indietro in un veicolo",
	"Necessário para a tecla de visão (primeira / terceira pessoa) e olhar para trás no veículo",
	"Potrzebne do klawisza widoku (pierwsza / trzecia osoba) i patrzenia do tyłu w pojeździe",
	"Görünüm tuşu (birinci / üçüncü şahıs) ve araçta arkaya bakmak için gerekli",
	"Potřeba pro klávesu pohledu (první / třetí osoba) a pohled dozadu ve vozidle" }
S.chk_input_melee = { "Trattenere Q (ASI)", "Segurar o Q (ASI)", "Wstrzymanie Q (ASI)", "Q'yu tutma (ASI)", "Zadržení Q (ASI)" }
S.chk_input_melee_d = { "Serve alla modalità rissa quando un nemico è stordito troppo presto",
	"Necessário ao modo briga quando um inimigo fica atordoado cedo",
	"Potrzebne trybowi bójki, gdy wróg jest ogłuszony za wcześnie",
	"Bir düşman erken sersemlediğinde kavga modu için gerekli",
	"Potřeba pro režim rvačky, když je nepřítel omráčen příliš brzy" }
S.chk_mouse4 = { "Tasto laterale del mouse (colpo finale)", "Botão lateral do mouse (finalização)", "Boczny przycisk myszy (dobicie)",
	"Farenin yan tuşu (bitiriş)", "Boční tlačítko myši (doraz)" }
S.chk_mouse4_off = { "Non usato dal 2026-10-21: finisce Q", "Sem uso desde 2026-10-21: o Q finaliza", "Nieużywany od 2026-10-21: dobija Q",
	"2026-10-21'den beri kullanılmıyor: Q bitirir", "Od 2026-10-21 se nepoužívá: dorazí Q" }
S.chk_data = { "Elenchi di auto, barche e hash", "Listas de carros, barcos e hashes", "Listy aut, łodzi i hashy",
	"Araba, tekne ve hash listeleri", "Seznamy aut, lodí a hashů" }
S.chk_modules = { "Moduli del trainer", "Módulos do trainer", "Moduły trainera", "Trainer modülleri", "Moduly traineru" }
S.chk_modules_d = { "Super corsa, rissa, sballo e prima persona sono collegati", "Supercorrida, briga, barato e primeira pessoa estão conectados",
	"Superbieg, bójka, haj i widok z pierwszej osoby są połączone", "Süper koşu, kavga, kafa ve birinci şahıs bağlı",
	"Superběh, rvačka, opojení a pohled z první osoby jsou propojené" }
S.chk_tick = { "L'aggiornamento per fotogramma", "A atualização por quadro", "Aktualizacja co klatkę", "Kare başına güncelleme",
	"Aktualizace v každém snímku" }
S.chk_tick_d = { "Eseguito senza errori", "Executou sem erros", "Wykonane bez błędów", "Hatasız çalıştı", "Proběhlo bez chyb" }
S.chk_health_d = { "La salute si legge: %s su %s", "A vida é lida: %s de %s", "Zdrowie odczytane: %s z %s", "Sağlık okunuyor: %s / %s",
	"Zdraví se čte: %s z %s" }
S.chk_god_d = { "Invincibilità attivata e disattivata di nuovo; il gioco l'ha accettato", "Modo deus ligado e desligado de novo; o jogo aceitou",
	"Nieśmiertelność włączona i wyłączona z powrotem; gra to przyjęła", "Ölümsüzlük açıldı ve tekrar kapatıldı; oyun kabul etti",
	"Nesmrtelnost zapnuta a zase vypnuta; hra to přijala" }
S.chk_style_d = { "Lo stile di controllo si legge: %s", "O estilo de controle é lido: %s", "Styl sterowania odczytany: %s",
	"Kontrol stili okunuyor: %s", "Styl ovládání se čte: %s" }
S.chk_health_low = { "Troppa poca salute per la prova", "Pouca vida para o teste", "Za mało zdrowia na próbę", "Deneme için sağlık çok az",
	"Na zkoušku je málo zdraví" }
S.chk_health_write_d = { "Il conteggio dei colpi passa per la salute: scritta, letta, rimessa",
	"A contagem de golpes passa pela vida: gravada, lida, devolvida",
	"Licznik ciosów idzie przez zdrowie: zapisane, odczytane, przywrócone",
	"Vuruş sayımı sağlık üzerinden gider: yazıldı, okundu, geri alındı",
	"Počítání ran jde přes zdraví: zapsáno, přečteno, vráceno" }
S.chk_hour_d = { "Ora spostata di un quarto d'ora e tornata: chiesto %s, ottenuto %s",
	"Hora movida um quarto de hora e de volta: pedido %s, obtido %s",
	"Czas przesunięty o kwadrans i z powrotem: żądano %s, wyszło %s",
	"Saat çeyrek saat ileri alınıp geri getirildi: istenen %s, çıkan %s",
	"Čas posunut o čtvrthodinu a zpět: požadováno %s, vyšlo %s" }
S.chk_traffic_d = { "Lo stato del traffico si legge: %s", "O estado do trânsito é lido: %s", "Stan ruchu odczytany: %s",
	"Trafik durumu okunuyor: %s", "Stav provozu se čte: %s" }
S.chk_corpses_d = { "Il conteggio dei corpi risponde", "A contagem de corpos responde", "Liczenie ciał odpowiada",
	"Ceset sayımı yanıt veriyor", "Počítání těl odpovídá" }
S.chk_squad = { "Squadre: arrivo in auto", "Esquadrões: chegada de carro", "Oddziały: przyjazd autem", "Ekipler: arabayla geliş",
	"Oddíly: příjezd autem" }
S.chk_no_fp = { "La prima persona non è caricata", "A primeira pessoa não está carregada", "Widok z pierwszej osoby nie jest wczytany",
	"Birinci şahıs yüklenmedi", "Pohled z první osoby není načten" }
S.chk_fp_eyes = { "Prima persona: gli occhi", "Primeira pessoa: os olhos", "Pierwsza osoba: oczy", "Birinci şahıs: gözler",
	"První osoba: oči" }
S.chk_fp_eyes_d = { "Occhi trovati (%s), %s m sopra i piedi", "Olhos encontrados (%s), %s m acima dos pés",
	"Oczy znalezione (%s), %s m nad stopami", "Gözler bulundu (%s), ayakların %s m üstünde", "Oči nalezeny (%s), %s m nad nohama" }
S.chk_fp_eyes_car_d = { "Occhi trovati (%s), %s m sopra l'auto", "Olhos encontrados (%s), %s m acima do carro",
	"Oczy znalezione (%s), %s m nad autem", "Gözler bulundu (%s), arabanın %s m üstünde", "Oči nalezeny (%s), %s m nad autem" }
S.chk_fp_eyes_none = { "Nessun osso di occhi o testa a un'altezza credibile", "Nenhum osso de olhos ou cabeça numa altura plausível",
	"Nie znaleziono kości oczu ani głowy na wiarygodnej wysokości", "Makul yükseklikte göz veya kafa kemiği yok",
	"Žádná kost očí ani hlavy ve věrohodné výšce" }
S.chk_fp_offset = { "Prima persona: spostare la telecamera", "Primeira pessoa: mover a câmera", "Pierwsza osoba: przesunięcie kamery",
	"Birinci şahıs: kamerayı kaydırma", "První osoba: posun kamery" }
S.chk_fp_offset_d = { "Telecamera alzata di 0,3 m e rimessa: si è spostata di %s m", "Câmera movida 0,3 m para cima e de volta: moveu %s m",
	"Kamera przesunięta 0,3 m w górę i z powrotem: przesunęła się o %s m", "Kamera 0,3 m yukarı alındı ve geri getirildi: %s m kaydı",
	"Kamera posunuta o 0,3 m nahoru a zpět: posunula se o %s m" }
S.chk_fp_fov = { "Prima persona: campo visivo a piedi", "Primeira pessoa: campo de visão a pé", "Pierwsza osoba: pole widzenia pieszo",
	"Birinci şahıs: yürürken görüş açısı", "První osoba: zorné pole pěšky" }
S.chk_fp_fov_d = { "Era %s, chiesto %s, diventato %s", "Era %s, pedido %s, ficou %s", "Było %s, żądano %s, jest %s",
	"Önce %s, istenen %s, olan %s", "Bylo %s, požadováno %s, je %s" }
S.chk_fp_fov_noread = { "Il gioco non riporta l'angolo della telecamera; impossibile verificare",
	"O jogo não informa o ângulo da câmera; não dá para verificar", "Gra nie podaje kąta kamery, nie da się sprawdzić",
	"Oyun kamera açısını bildirmiyor; kontrol edilemez", "Hra nehlásí úhel kamery; nelze ověřit" }
S.chk_fp_anchor_fov = { "Prima persona: campo visivo nei veicoli", "Primeira pessoa: campo de visão em veículos",
	"Pierwsza osoba: pole widzenia w pojeździe", "Birinci şahıs: araçta görüş açısı", "První osoba: zorné pole ve vozidle" }
S.chk_fp_anchor_noapi = { "La telecamera nella testa non ha un campo visivo regolabile", "A câmera na cabeça não tem campo de visão ajustável",
	"Kamera w głowie nie ma regulowanego pola widzenia", "Kafa kamerasının ayarlanabilir görüş açısı yok",
	"Kamera v hlavě nemá nastavitelné zorné pole" }
S.chk_fp_config = { "Prima persona: config della telecamera del gioco", "Primeira pessoa: config de câmera do jogo",
	"Pierwsza osoba: konfiguracja kamery gry", "Birinci şahıs: oyunun kamera ayarı", "První osoba: konfigurace kamery hry" }
S.chk_fp_config_on = { "Installata (tables.sds)", "Instalada (tables.sds)", "Zainstalowana (tables.sds)", "Kurulu (tables.sds)",
	"Nainstalována (tables.sds)" }
S.chk_fp_config_off = { "Non installata: IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat a gioco chiuso",
	"Não instalada: IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat com o jogo fechado",
	"Niezainstalowana: IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat przy zamkniętej grze",
	"Kurulu değil: oyun kapalıyken IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat",
	"Nenainstalována: IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat při zavřené hře" }
S.chk_fp_config_unknown = { "Si saprà quando la visuale sarà attiva a piedi", "Saberemos quando a visão estiver ligada a pé",
	"Będzie wiadomo, gdy widok zostanie włączony pieszo", "Görünüm yürürken açılınca belli olur",
	"Ukáže se, až bude pohled zapnut pěšky" }
S.chk_fp_carshoot = { "Prima persona: sparare dall'auto dagli occhi", "Primeira pessoa: atirar do carro pelos olhos",
	"Pierwsza osoba: strzelanie z auta od oczu", "Birinci şahıs: arabadan gözden ateş", "První osoba: střelba z auta od očí" }
S.chk_fp_carshoot_off = { "In questa sessione la telecamera del gioco non ha seguito il mouse: mira lei",
	"Nesta sessão a câmera do jogo não girou com o mouse: ela mira",
	"W tej sesji kamera gry nie obróciła się za myszą: celuje ona",
	"Bu oturumda oyun kamerası fareyle dönmedi: nişanı o alıyor",
	"V této relaci se kamera hry neotočila s myší: míří ona" }
S.chk_fp_carshoot_unknown = { "Si saprà quando sparerai da un'auto", "Saberemos quando você atirar de um carro",
	"Będzie wiadomo, gdy strzelisz z auta", "Arabadan ateş edince belli olur", "Ukáže se, až vystřelíš z auta" }
S.chk_fp_carshoot_ok = { "La telecamera del gioco segue il mouse: mira dagli occhi", "A câmera do jogo gira com o mouse: mira pelos olhos",
	"Kamera gry obraca się za myszą: celowanie od oczu", "Oyun kamerası fareyle dönüyor: gözden nişan",
	"Kamera hry se otáčí s myší: míření od očí" }
S.loaded = { "menu pronto: F4", "menu pronto: F4", "menu gotowe: F4", "menü hazır: F4", "nabídka připravena: F4" }
S.reloaded = { "ricaricato, invincibilità azzerata", "recarregado, modo deus desligado", "przeładowano, nieśmiertelność zresetowana",
	"yeniden yüklendi, ölümsüzlük sıfırlandı", "znovu načteno, nesmrtelnost zrušena" }
S.corpses_n = { "corpi vicini: %d", "corpos por perto: %d", "ciała w pobliżu: %d", "yakındaki cesetler: %d", "těla poblíž: %d" }
S.lang_set = { "lingua: %s", "idioma: %s", "język: %s", "dil: %s", "jazyk: %s" }

-- labels of the old trainer (English key as in I18n.Legacy)
-- camera
L["Camera Controls"] = { "Telecamera libera", "Câmera livre", "Wolna kamera", "Serbest kamera", "Volná kamera" }
L["Toggle Freecam"] = { "Telecamera libera", "Câmera livre", "Wolna kamera", "Serbest kamera", "Volná kamera" }
L["Toggle Freecam Type"] = { "Modalità telecamera libera", "Modo da câmera livre", "Tryb wolnej kamery", "Serbest kamera modu", "Režim volné kamery" }
L["Freecam Settings"] = { "Impostazioni telecamera libera", "Configurações da câmera livre", "Ustawienia wolnej kamery", "Serbest kamera ayarları", "Nastavení volné kamery" }
L["Camera Offset Menu"] = { "Spostamento", "Deslocamento", "Przesunięcie", "Kaydırma", "Posun" }
L["Camera FOV Menu"] = { "Campo visivo", "Campo de visão", "Pole widzenia", "Görüş açısı", "Zorné pole" }
L["Camera Direction Menu"] = { "Direzione", "Direção", "Kierunek", "Yön", "Směr" }
L["Camera Look At Entity Menu"] = { "Guarda un'entità", "Olhar para uma entidade", "Patrz na obiekt", "Bir nesneye bak", "Dívat se na objekt" }
L["Camera Lock To Entity Menu"] = { "Aggancia a un'entità", "Fixar em uma entidade", "Przypnij do obiektu", "Bir nesneye kilitle", "Připnout k objektu" }
L["Reset Camera"] = { "Ripristina telecamera", "Redefinir câmera", "Zresetuj kamerę", "Kamerayı sıfırla", "Obnovit kameru" }
L["Camera Info"] = { "Info telecamera", "Info da câmera", "Dane kamery", "Kamera bilgisi", "Info o kameře" }
L["Camera Offset Controls"] = { "Spostamento telecamera", "Deslocamento da câmera", "Przesunięcie kamery", "Kamera kaydırma", "Posun kamery" }
L["Camera Offset X Value"] = { "Spostamento X", "Deslocamento X", "Przesunięcie X", "Kaydırma X", "Posun X" }
L["Camera Offset Y Value"] = { "Spostamento Y", "Deslocamento Y", "Przesunięcie Y", "Kaydırma Y", "Posun Y" }
L["Camera Offset Z Value"] = { "Spostamento Z", "Deslocamento Z", "Przesunięcie Z", "Kaydırma Z", "Posun Z" }
L["Camera Offset Transition Time In Value"] = { "Tempo di entrata", "Tempo de entrada", "Czas wejścia", "Giriş süresi", "Doba náběhu" }
L["Camera Offset Transition Time Out Value"] = { "Tempo di uscita", "Tempo de saída", "Czas wyjścia", "Çıkış süresi", "Doba doběhu" }
L["Camera Offset Wait Time Value"] = { "Tempo di attesa", "Tempo de espera", "Czas oczekiwania", "Bekleme süresi", "Doba čekání" }
L["Offset Camera"] = { "Sposta la telecamera", "Deslocar câmera", "Przesuń kamerę", "Kamerayı kaydır", "Posunout kameru" }
L["Camera FOV Controls"] = { "Campo visivo della telecamera", "Campo de visão da câmera", "Pole widzenia kamery", "Kamera görüş açısı", "Zorné pole kamery" }
L["Camera FOV Value"] = { "Campo visivo", "Campo de visão", "Pole widzenia", "Görüş açısı", "Zorné pole" }
L["Camera Wait Time Value"] = { "Tempo di attesa", "Tempo de espera", "Czas oczekiwania", "Bekleme süresi", "Doba čekání" }
L["Camera FOV Transition Time In Value"] = { "Tempo di entrata", "Tempo de entrada", "Czas wejścia", "Giriş süresi", "Doba náběhu" }
L["Camera FOV Transition Time Out Value"] = { "Tempo di uscita", "Tempo de saída", "Czas wyjścia", "Çıkış süresi", "Doba doběhu" }
L["Change Camera FOV"] = { "Applica campo visivo", "Aplicar campo de visão", "Zastosuj pole widzenia", "Görüş açısını uygula", "Použít zorné pole" }
L["Camera Direction Controls"] = { "Direzione telecamera", "Direção da câmera", "Kierunek kamery", "Kamera yönü", "Směr kamery" }
L["Camera Look At X Value"] = { "Guarda X", "Olhar para X", "Cel wzroku X", "Bakış X", "Cíl pohledu X" }
L["Camera Look At Y Value"] = { "Guarda Y", "Olhar para Y", "Cel wzroku Y", "Bakış Y", "Cíl pohledu Y" }
L["Camera Look At Z Value"] = { "Guarda Z", "Olhar para Z", "Cel wzroku Z", "Bakış Z", "Cíl pohledu Z" }
L["Camera Transition Time Value"] = { "Tempo di transizione", "Tempo de transição", "Czas przejścia", "Geçiş süresi", "Doba přechodu" }
L["Change Camera Direction"] = { "Applica direzione", "Aplicar direção", "Zastosuj kierunek", "Yönü uygula", "Použít směr" }
L["Camera Look at Entity Controls"] = { "La telecamera guarda un'entità", "A câmera olha para uma entidade", "Kamera patrzy na obiekt", "Kamera bir nesneye bakar", "Kamera se dívá na objekt" }
L["Camera Target Entity Name"] = { "Nome del bersaglio", "Nome do alvo", "Nazwa celu", "Hedef adı", "Název cíle" }
L["Look at Entity"] = { "Guarda l'entità", "Olhar para a entidade", "Patrz na obiekt", "Nesneye bak", "Dívat se na objekt" }
L["Camera Target Offset Menu"] = { "Spostamento del bersaglio", "Deslocamento do alvo", "Przesunięcie celu", "Hedef kaydırma", "Posun cíle" }
L["Camera Target X Offset"] = { "Spostamento X del bersaglio", "Deslocamento X do alvo", "Przesunięcie celu X", "Hedef kaydırma X", "Posun cíle X" }
L["Camera Target Y Offset"] = { "Spostamento Y del bersaglio", "Deslocamento Y do alvo", "Przesunięcie celu Y", "Hedef kaydırma Y", "Posun cíle Y" }
L["Camera Target Z Offset"] = { "Spostamento Z del bersaglio", "Deslocamento Z do alvo", "Przesunięcie celu Z", "Hedef kaydırma Z", "Posun cíle Z" }
L["Camera Entity Name"] = { "Nome dell'entità", "Nome da entidade", "Nazwa obiektu", "Nesne adı", "Název objektu" }
L["Lock to Entity"] = { "Aggancia all'entità", "Fixar na entidade", "Przypnij do obiektu", "Nesneye kilitle", "Připnout k objektu" }
L["Set Speed"] = { "Velocità", "Velocidade", "Prędkość", "Hız", "Rychlost" }
L["Set Rotation Speed"] = { "Velocità di rotazione", "Velocidade de rotação", "Prędkość obrotu", "Dönüş hızı", "Rychlost otáčení" }
L["Toggle Depth of Field"] = { "Profondità di campo", "Profundidade de campo", "Głębia ostrości", "Alan derinliği", "Hloubka ostrosti" }
L["Set Focus Distance"] = { "Distanza di messa a fuoco", "Distância de foco", "Odległość ostrości", "Odak mesafesi", "Vzdálenost zaostření" }
L["Set FOV"] = { "Campo visivo", "Campo de visão", "Pole widzenia", "Görüş açısı", "Zorné pole" }
L["Enter X Offset Value (use only integers)"] = { "Spostamento X (numero intero)", "Deslocamento X (número inteiro)", "Przesunięcie X (liczba całkowita)", "Kaydırma X (tam sayı)", "Posun X (celé číslo)" }
L["Enter Y Offset Value (use only integers)"] = { "Spostamento Y (numero intero)", "Deslocamento Y (número inteiro)", "Przesunięcie Y (liczba całkowita)", "Kaydırma Y (tam sayı)", "Posun Y (celé číslo)" }
L["Enter Z Offset Value (use only integers)"] = { "Spostamento Z (numero intero)", "Deslocamento Z (número inteiro)", "Przesunięcie Z (liczba całkowita)", "Kaydırma Z (tam sayı)", "Posun Z (celé číslo)" }
L["Enter X offset value (Use only integers)"] = { "Spostamento X (numero intero)", "Deslocamento X (número inteiro)", "Przesunięcie X (liczba całkowita)", "Kaydırma X (tam sayı)", "Posun X (celé číslo)" }
L["Enter Y offset value (Use only integers)"] = { "Spostamento Y (numero intero)", "Deslocamento Y (número inteiro)", "Przesunięcie Y (liczba całkowita)", "Kaydırma Y (tam sayı)", "Posun Y (celé číslo)" }
L["Enter Z offset value (Use only integers)"] = { "Spostamento Z (numero intero)", "Deslocamento Z (número inteiro)", "Przesunięcie Z (liczba całkowita)", "Kaydırma Z (tam sayı)", "Posun Z (celé číslo)" }
L["Enter Entity Name"] = { "Nome dell'entità", "Nome da entidade", "Nazwa obiektu", "Nesne adı", "Název objektu" }
L["Enter entity name"] = { "Nome dell'entità", "Nome da entidade", "Nazwa obiektu", "Nesne adı", "Název objektu" }
L["Enter Target Entity Name"] = { "Nome dell'entità bersaglio", "Nome da entidade alvo", "Nazwa obiektu docelowego", "Hedef nesne adı", "Název cílového objektu" }
L["Enter Transition Time value (Use only integers)"] = { "Tempo di transizione (numero intero)", "Tempo de transição (número inteiro)", "Czas przejścia (liczba całkowita)", "Geçiş süresi (tam sayı)", "Doba přechodu (celé číslo)" }
L["Enter Transition Time In value (Use only integers)"] = { "Tempo di entrata (numero intero)", "Tempo de entrada (número inteiro)", "Czas wejścia (liczba całkowita)", "Giriş süresi (tam sayı)", "Doba náběhu (celé číslo)" }
L["Enter Transition Time Out value (Use only integers)"] = { "Tempo di uscita (numero intero)", "Tempo de saída (número inteiro)", "Czas wyjścia (liczba całkowita)", "Çıkış süresi (tam sayı)", "Doba doběhu (celé číslo)" }
L["Enter Transition Time Out (Use only integers)"] = { "Tempo di uscita (numero intero)", "Tempo de saída (número inteiro)", "Czas wyjścia (liczba całkowita)", "Çıkış süresi (tam sayı)", "Doba doběhu (celé číslo)" }
L["Enter FOV value (Use only integers)"] = { "Campo visivo (numero intero)", "Campo de visão (número inteiro)", "Pole widzenia (liczba całkowita)", "Görüş açısı (tam sayı)", "Zorné pole (celé číslo)" }
L["Enter Wait Time value (Use only integers)"] = { "Tempo di attesa (numero intero)", "Tempo de espera (número inteiro)", "Czas oczekiwania (liczba całkowita)", "Bekleme süresi (tam sayı)", "Doba čekání (celé číslo)" }
L["Enter Wait time value (Use only integers)"] = { "Tempo di attesa (numero intero)", "Tempo de espera (número inteiro)", "Czas oczekiwania (liczba całkowita)", "Bekleme süresi (tam sayı)", "Doba čekání (celé číslo)" }
L["Enter X value (Use only integers)"] = { "Valore X (numero intero)", "Valor X (número inteiro)", "Wartość X (liczba całkowita)", "X değeri (tam sayı)", "Hodnota X (celé číslo)" }
L["Enter Y value (Use only integers)"] = { "Valore Y (numero intero)", "Valor Y (número inteiro)", "Wartość Y (liczba całkowita)", "Y değeri (tam sayı)", "Hodnota Y (celé číslo)" }
L["Enter Z value (Use only integers)"] = { "Valore Z (numero intero)", "Valor Z (número inteiro)", "Wartość Z (liczba całkowita)", "Z değeri (tam sayı)", "Hodnota Z (celé číslo)" }
L["Enter Focus Distance value (Use only integers)"] = { "Distanza di messa a fuoco (numero intero)", "Distância de foco (número inteiro)", "Odległość ostrości (liczba całkowita)", "Odak mesafesi (tam sayı)", "Vzdálenost zaostření (celé číslo)" }
L["Enter FOV value (0.01 - 110)"] = { "Campo visivo (0.01–110)", "Campo de visão (0.01–110)", "Pole widzenia (0.01–110)", "Görüş açısı (0.01–110)", "Zorné pole (0.01–110)" }
L["Enter Speed value (Use only integers)"] = { "Velocità (numero intero)", "Velocidade (número inteiro)", "Prędkość (liczba całkowita)", "Hız (tam sayı)", "Rychlost (celé číslo)" }

-- first-person view
L["First-person view"] = { "Visuale in prima persona", "Visão em primeira pessoa", "Widok z pierwszej osoby", "Birinci şahıs görünümü", "Pohled z první osoby" }
L["Camera in Lincoln's eyes: you see hands, weapon and the steering wheel. On by default, the choice is remembered"] = {
	"Telecamera negli occhi di Lincoln: vedi mani, arma e volante. Attiva di base, la scelta viene ricordata",
	"Câmera nos olhos do Lincoln: você vê mãos, arma e volante. Ligada por padrão, a escolha fica salva",
	"Kamera w oczach Lincolna: widać ręce, broń i kierownicę. Domyślnie włączony, wybór jest zapamiętywany",
	"Kamera Lincoln'ün gözlerinde: eller, silah ve direksiyon görünür. Varsayılan açık, seçim hatırlanır",
	"Kamera v Lincolnových očích: vidíš ruce, zbraň a volant. Výchozí zapnuto, volba se pamatuje" }
L["Show body, hands and weapon"] = { "Mostra corpo, mani e arma", "Mostrar corpo, mãos e arma", "Pokazuj ciało, ręce i broń", "Vücudu, elleri ve silahı göster", "Zobrazit tělo, ruce a zbraň" }
L["Off hides the whole model, weapon included"] = { "No nasconde tutto il modello, arma compresa", "Não esconde o modelo todo, arma incluída", "Wył. ukrywa cały model razem z bronią", "Kapalı, silah dahil tüm modeli gizler", "Vyp. skryje celý model i se zbraní" }
L["Also in vehicles"] = { "Anche nei veicoli", "Também em veículos", "Także w pojazdach", "Araçlarda da", "I ve vozidlech" }
L["Driver's seat view; the camera follows the car"] = { "Vista dal posto di guida; la telecamera segue l'auto", "Visão do banco do motorista; a câmera segue o carro", "Widok z fotela kierowcy; kamera podąża za autem", "Sürücü koltuğu görünümü; kamera arabayı izler", "Pohled z místa řidiče; kamera sleduje auto" }
L["Camera"] = { "Telecamera", "Câmera", "Kamera", "Kamera", "Kamera" }
L["Camera mode"] = { "Modalità telecamera", "Modo da câmera", "Tryb kamery", "Kamera modu", "Režim kamery" }
L["Game camera: native mouse, aim and driving — offset pulls view to the eyes. Locked: anchor rig"] = { "Del gioco: mouse, mira e guida nativi — lo spostamento porta la vista agli occhi. Fissa: ancora", "Do jogo: mouse, mira e direção nativos — o deslocamento leva a visão aos olhos. Fixa: âncora", "Kamera gry: natywna mysz, celowanie i jazda — przesunięcie do oczu. Przypięta: kotwica", "Oyun kamerası: doğal fare, nişan ve sürüş — kaydırma görüşü gözlere çeker. Sabit: çapa", "Kamera hry: nativní myš, míření a jízda — posun k očím. Pevná: kotva" }
L["Game camera: stand still, hold mouse still ~1 s to calibrate"] = { "Telecamera del gioco: stai fermo, mouse immobile ~1 s per calibrare", "Câmera do jogo: fique parado, mouse parado ~1 s para calibrar", "Kamera gry: stój, nie ruszaj myszą ~1 s — kalibracja", "Oyun kamerası: dur, kalibrasyon için fareyi ~1 sn oynatma", "Kamera hry: stůj, myší ~1 s nehýbej — kalibrace" }
L["Game camera: stop the car, hold mouse still ~1 s to calibrate"] = { "In auto: fermati, mouse immobile ~1 s", "No carro: pare, mouse parado ~1 s", "W aucie: zatrzymaj się, nie ruszaj myszą ~1 s", "Arabada: dur, fareyi ~1 sn oynatma", "V autě: zastav, myší ~1 s nehýbej" }
L["Game camera"] = { "Del gioco", "Do jogo", "Kamera gry", "Oyun kamerası", "Kamera hry" }
L["Locked camera"] = { "Fissa", "Câmera fixa", "Przypięta", "Sabit kamera", "Pevná kamera" }
L["Game camera: native mouse look and aiming. Locked camera: the fallback"] = { "Del gioco: visuale col mouse e mira nativi. Fissa: la riserva", "Do jogo: visão com mouse e mira nativos. Fixa: a alternativa", "Kamera gry: natywne rozglądanie myszą i celowanie. Przypięta: zapasowa", "Oyun kamerası: doğal fare bakışı ve nişan. Sabit kamera: yedek", "Kamera hry: nativní rozhlížení myší a míření. Pevná: záloha" }
L["Head bob"] = { "Oscillazione della testa", "Balanço da cabeça", "Kołysanie głowy", "Kafa sallanması", "Pohupování hlavy" }
L["How much the view follows the head while walking"] = { "Quanto la vista segue la testa camminando", "Quanto a visão segue a cabeça ao andar", "Jak bardzo widok podąża za głową podczas chodzenia", "Yürürken görüşün kafayı ne kadar izlediği", "Jak moc pohled sleduje hlavu při chůzi" }
L["Off"] = { "No", "Não", "Wył.", "Kapalı", "Vyp." }
L["On"] = { "Sì", "Sim", "Wł.", "Açık", "Zap." }
L["Low"] = { "Basso", "Baixo", "Słabe", "Düşük", "Slabé" }
L["Full"] = { "Pieno", "Completo", "Pełne", "Tam", "Plné" }
L["Field of view"] = { "Campo visivo", "Campo de visão", "Pole widzenia", "Görüş açısı", "Zorné pole" }
L["Game"] = { "Come nel gioco", "Como no jogo", "Jak w grze", "Oyundaki gibi", "Jako ve hře" }
L["Game keeps the game's own angle, aiming zoom included"] = { "«Come nel gioco» tiene l'angolo originale, zoom di mira compreso", "“Como no jogo” mantém o ângulo original, zoom da mira incluído", "„Jak w grze” zostawia własny kąt gry razem z przybliżeniem przy celowaniu", "“Oyundaki gibi” oyunun kendi açısını korur, nişan yakınlaştırması dahil", "„Jako ve hře“ ponechá vlastní úhel hry i s přiblížením při míření" }
L["Camera forward"] = { "Telecamera avanti", "Câmera à frente", "Kamera do przodu", "Kamera ileri", "Kamera dopředu" }
L["Metres in front of the eyes; more if you see the inside of the head"] = { "Metri davanti agli occhi; di più se vedi l'interno della testa", "Metros à frente dos olhos; mais se você vir o interior da cabeça", "Metry przed oczami; dodaj, jeśli widać głowę od środka", "Gözlerin önündeki metre; kafanın içi görünüyorsa artır", "Metry před očima; přidej, pokud je vidět hlava zevnitř" }
L["Camera height"] = { "Altezza telecamera", "Altura da câmera", "Wysokość kamery", "Kamera yüksekliği", "Výška kamery" }
L["Metres above or below the eyes"] = { "Metri sopra o sotto gli occhi", "Metros acima ou abaixo dos olhos", "Metry powyżej lub poniżej oczu", "Gözlerin üstünde veya altında metre", "Metry nad nebo pod očima" }
L["Speed correction"] = { "Correzione velocità", "Correção de velocidade", "Korekta prędkości", "Hız düzeltmesi", "Korekce rychlosti" }
L["Switch it if at speed the view slides away from the head"] = { "Cambialo se in velocità la vista si allontana dalla testa", "Mude se em velocidade a visão se afasta da cabeça", "Przełącz, jeśli przy prędkości widok odjeżdża od głowy", "Hızda görüş kafadan kayıyorsa değiştir", "Přepni, pokud při rychlosti pohled ujíždí od hlavy" }
L["Service"] = { "Manutenzione", "Manutenção", "Serwis", "Bakım", "Údržba" }
L["Recalibrate the camera"] = { "Ricalibra la telecamera", "Recalibrar a câmera", "Skalibruj kamerę ponownie", "Kamerayı yeniden kalibre et", "Překalibrovat kameru" }
L["Measure again if the view drifts off the eyes"] = { "Misura di nuovo se la vista si allontana dagli occhi", "Meça de novo se a visão se afastar dos olhos", "Zmierz ponownie, jeśli widok odpływa od oczu", "Görüş gözlerden kayarsa yeniden ölç", "Změř znovu, pokud pohled ujíždí od očí" }
L["Write camera state to the log"] = { "Scrivi lo stato della telecamera nel log", "Gravar o estado da câmera no log", "Zapisz stan kamery do logu", "Kamera durumunu günlüğe yaz", "Zapsat stav kamery do logu" }
L["ScriptHook.log: bones, camera, calibration"] = { "ScriptHook.log: ossa, telecamera, calibrazione", "ScriptHook.log: ossos, câmera, calibração", "ScriptHook.log: kości, kamera, kalibracja", "ScriptHook.log: kemikler, kamera, kalibrasyon", "ScriptHook.log: kosti, kamera, kalibrace" }
L["First-person: stand still and hold the mouse still for a second to set up the camera"] = { "Prima persona: stai fermo e non muovere il mouse per un secondo per impostare la telecamera", "Primeira pessoa: fique parado e não mexa o mouse por um segundo para ajustar a câmera", "Pierwsza osoba: postój sekundę i nie ruszaj myszą, kamera się ustawi", "Birinci şahıs: kamerayı ayarlamak için bir saniye dur ve fareyi oynatma", "První osoba: chvíli stůj a nehýbej myší, kamera se nastaví" }
L["First-person: stop the car and hold the mouse still for a second to set up the camera"] = { "Prima persona: ferma l'auto e non muovere il mouse per un secondo per impostare la telecamera", "Primeira pessoa: pare o carro e não mexa o mouse por um segundo para ajustar a câmera", "Pierwsza osoba: zatrzymaj auto na sekundę i nie ruszaj myszą, kamera się ustawi", "Birinci şahıs: kamerayı ayarlamak için arabayı bir saniye durdur ve fareyi oynatma", "První osoba: na chvíli zastav auto a nehýbej myší, kamera se nastaví" }
L["First-person: ready"] = { "Prima persona: telecamera pronta", "Primeira pessoa: câmera ajustada", "Pierwsza osoba: kamera ustawiona", "Birinci şahıs: kamera hazır", "První osoba: kamera nastavena" }
L["First-person: the game camera did not follow, using the locked camera"] = { "Prima persona: la telecamera del gioco non segue, uso la telecamera fissa", "Primeira pessoa: a câmera do jogo não seguiu, usando a câmera fixa", "Pierwsza osoba: kamera gry nie słucha, włączona przypięta", "Birinci şahıs: oyun kamerası izlemedi, sabit kamera kullanılıyor", "První osoba: kamera hry neposlouchá, zapnuta pevná" }
L["First-person: calibration cleared"] = { "Prima persona: calibrazione azzerata, la telecamera verrà misurata di nuovo", "Primeira pessoa: calibração apagada, a câmera será medida de novo", "Pierwsza osoba: kalibracja wyczyszczona, kamera zostanie zmierzona ponownie", "Birinci şahıs: kalibrasyon silindi, kamera yeniden ölçülecek", "První osoba: kalibrace smazána, kamera se změří znovu" }
L["First-person: the game camera did not follow — try Recalibrate or the locked camera"] = { "Prima persona: la telecamera del gioco non segue — ricalibra o usa la telecamera fissa", "Primeira pessoa: a câmera do jogo não seguiu — recalibre ou use a câmera fixa", "Pierwsza osoba: kamera gry nie słucha — skalibruj ponownie lub włącz przypiętą", "Birinci şahıs: oyun kamerası izlemedi — yeniden kalibre et veya sabit kamerayı kullan", "První osoba: kamera hry neposlouchá — překalibruj nebo zapni pevnou" }
L["Head camera"] = { "Telecamera nella testa", "Câmera na cabeça", "Kamera w głowie", "Kafa kamerası", "Kamera v hlavě" }
L["Head camera: held at the eyes, like first-person mods in GTA. Game camera: the game's own camera, stops just behind the head on foot"] = { "Nella testa: tenuta agli occhi, come le mod in prima persona di GTA. Del gioco: la telecamera originale, a piedi si ferma appena dietro la testa", "Na cabeça: presa aos olhos, como os mods de primeira pessoa do GTA. Do jogo: a câmera original, a pé para logo atrás da cabeça", "W głowie: trzymana przy oczach, jak w modach z pierwszej osoby do GTA. Kamera gry: własna kamera gry, pieszo zatrzymuje się tuż za głową", "Kafa kamerası: GTA'daki birinci şahıs modları gibi gözlerde tutulur. Oyun kamerası: oyunun kendi kamerası, yürürken kafanın hemen arkasında durur", "V hlavě: držená u očí jako módy z první osoby v GTA. Kamera hry: vlastní kamera hry, pěšky se zastaví těsně za hlavou" }
L["Mouse sensitivity"] = { "Sensibilità del mouse", "Sensibilidade do mouse", "Czułość myszy", "Fare hassasiyeti", "Citlivost myši" }
L["How fast the head camera turns with the mouse"] = { "Quanto velocemente la telecamera nella testa gira col mouse", "Quão rápido a câmera na cabeça gira com o mouse", "Jak szybko kamera w głowie obraca się myszą", "Kafa kamerasının fareyle ne kadar hızlı döndüğü", "Jak rychle se kamera v hlavě otáčí myší" }
L["Frame lead"] = { "Anticipo del fotogramma", "Antecipação de quadro", "Wyprzedzenie klatki", "Kare önceliği", "Předstih snímku" }
L["Keeps the camera from trailing the head while running; turn off if it runs ahead"] = { "Evita che la telecamera resti indietro rispetto alla testa in corsa; disattiva se va avanti", "Evita que a câmera fique atrás da cabeça ao correr; desligue se ela se adiantar", "Żeby w biegu kamera nie zostawała za głową; wyłącz, jeśli ucieka do przodu", "Koşarken kameranın kafanın gerisinde kalmasını önler; öne kaçıyorsa kapat", "Aby kamera při běhu nezaostávala za hlavou; vypni, pokud utíká dopředu" }
L["Tests again how walking follows the view and how the game camera moves (stand still ~4 s)"] = { "Riprova come la camminata segue la vista e come si muove la telecamera del gioco (fermo ~4 s)", "Testa de novo como o andar segue a visão e como a câmera do jogo se move (parado ~4 s)", "Ponownie sprawdza, jak chód podąża za wzrokiem i jak porusza się kamera gry (postój ~4 s)", "Yürümenin bakışı nasıl izlediğini ve oyun kamerasının nasıl hareket ettiğini yeniden test eder (~4 sn dur)", "Znovu ověří, jak chůze sleduje pohled a jak se hýbe kamera hry (stůj ~4 s)" }
L["First-person: stand still for a few seconds, setting up walking"] = { "Prima persona: stai fermo qualche secondo, imposto la camminata", "Primeira pessoa: fique parado alguns segundos, ajustando o andar", "Pierwsza osoba: postój kilka sekund, ustawiam chód za wzrokiem", "Birinci şahıs: birkaç saniye dur, yürüme ayarlanıyor", "První osoba: pár sekund stůj, nastavuji chůzi" }
L["First-person: walking does not follow the head camera here — use the game camera mode"] = { "Prima persona: la camminata non segue la telecamera nella testa — usa la modalità del gioco", "Primeira pessoa: o andar não segue a câmera na cabeça — use o modo câmera do jogo", "Pierwsza osoba: chód nie podąża za kamerą w głowie — włącz tryb „Kamera gry”", "Birinci şahıs: yürüme kafa kamerasını izlemiyor — oyun kamerası modunu kullan", "První osoba: chůze nesleduje kameru v hlavě — zapni režim „Kamera hry“" }
L["First-person: shooting from a car uses the game's camera (it does not aim from the eyes here)"] = { "Prima persona: sparando dall'auto si usa la telecamera del gioco (qui non mira dagli occhi)", "Primeira pessoa: atirando do carro usa a câmera do jogo (aqui ela não mira pelos olhos)", "Pierwsza osoba: przy strzelaniu z auta działa kamera gry (tu nie celuje od oczu)", "Birinci şahıs: arabadan ateş ederken oyun kamerası kullanılır (burada gözden nişan almaz)", "První osoba: při střelbě z auta funguje kamera hry (tady nemíří od očí)" }
L["First-person: the game camera did not follow — try Recalibrate or the head camera"] = { "Prima persona: la telecamera del gioco non segue — ricalibra o usa la telecamera nella testa", "Primeira pessoa: a câmera do jogo não seguiu — recalibre ou use a câmera na cabeça", "Pierwsza osoba: kamera gry nie słucha — skalibruj ponownie lub włącz kamerę w głowie", "Birinci şahıs: oyun kamerası izlemedi — yeniden kalibre et veya kafa kamerasını kullan", "První osoba: kamera hry neposlouchá — překalibruj nebo zapni kameru v hlavě" }
L["Body turns with the view"] = { "Il corpo segue la vista", "O corpo gira com a visão", "Ciało obraca się za wzrokiem", "Vücut bakışla döner", "Tělo se otáčí za pohledem" }
L["Standing still, Lincoln turns to where you look, like in GTA"] = { "Da fermo, Lincoln si gira dove guardi, come in GTA", "Parado, o Lincoln vira para onde você olha, como no GTA", "Stojąc w miejscu, Lincoln obraca się tam, gdzie patrzysz, jak w GTA", "Dururken Lincoln baktığın yöne döner, GTA'daki gibi", "Ve stoje se Lincoln otočí, kam se díváš, jako v GTA" }
L["Game camera: native mouse, aim and driving, held at the eyes. Locked camera: the fallback"] = { "Del gioco: mouse, mira e guida nativi, tenuta agli occhi. Fissa: la riserva", "Do jogo: mouse, mira e direção nativos, presa aos olhos. Fixa: a alternativa", "Kamera gry: natywna mysz, celowanie i jazda, trzymana przy oczach. Przypięta: zapasowa", "Oyun kamerası: doğal fare, nişan ve sürüş, gözlerde tutulur. Sabit kamera: yedek", "Kamera hry: nativní myš, míření a jízda, držená u očí. Pevná: záloha" }
L["Measures how the game camera moves (stand still ~2 s). Use it if the view drifts off the eyes"] = { "Misura come si muove la telecamera del gioco (fermo ~2 s). Usalo se la vista si allontana dagli occhi", "Mede como a câmera do jogo se move (parado ~2 s). Use se a visão se afastar dos olhos", "Mierzy, jak porusza się kamera gry (postój ~2 s). Użyj, jeśli widok odpływa od oczu", "Oyun kamerasının nasıl hareket ettiğini ölçer (~2 sn dur). Görüş gözlerden kayarsa kullan", "Změří, jak se hýbe kamera hry (stůj ~2 s). Použij, pokud pohled ujíždí od očí" }
L["First-person: the game's own first-person camera is installed (tables.sds)"] = { "Prima persona: è installata la telecamera in prima persona del gioco (tables.sds)", "Primeira pessoa: a câmera de primeira pessoa do próprio jogo está instalada (tables.sds)", "Pierwsza osoba: zainstalowana własna kamera FPS gry (tables.sds)", "Birinci şahıs: oyunun kendi birinci şahıs kamerası kurulu (tables.sds)", "První osoba: je nainstalována vlastní FPS kamera hry (tables.sds)" }
L["First-person: the camera patch is not installed — IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat with the game closed"] = { "Prima persona: la patch della telecamera non è installata — IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat a gioco chiuso", "Primeira pessoa: o patch de câmera não está instalado — IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat com o jogo fechado", "Pierwsza osoba: łatka kamery nie jest zainstalowana — uruchom IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat przy zamkniętej grze", "Birinci şahıs: kamera yaması kurulu değil — oyun kapalıyken IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat", "První osoba: patch kamery není nainstalován — spusť IRIDIUM\\fp_camera\\INSTALL_FP_CAMERA.bat při zavřené hře" }
L["First person stays: it is in the game camera config. Third person again: IRIDIUM\\fp_camera\\UNINSTALL_FP_CAMERA.bat"] = { "La prima persona resta: è nella config della telecamera del gioco. Di nuovo terza persona: IRIDIUM\\fp_camera\\UNINSTALL_FP_CAMERA.bat", "A primeira pessoa continua: está na config de câmera do jogo. Voltar à terceira pessoa: IRIDIUM\\fp_camera\\UNINSTALL_FP_CAMERA.bat", "Pierwsza osoba zostaje: jest w konfiguracji kamery gry. Powrót do trzeciej osoby: IRIDIUM\\fp_camera\\UNINSTALL_FP_CAMERA.bat", "Birinci şahıs kalır: oyunun kamera ayarında. Tekrar üçüncü şahıs: IRIDIUM\\fp_camera\\UNINSTALL_FP_CAMERA.bat", "První osoba zůstane: je v konfiguraci kamery hry. Zpět na třetí osobu: IRIDIUM\\fp_camera\\UNINSTALL_FP_CAMERA.bat" }
L["Check the game camera config"] = { "Controlla la config della telecamera del gioco", "Verificar a config de câmera do jogo", "Sprawdź konfigurację kamery gry", "Oyunun kamera ayarını kontrol et", "Zkontrolovat konfiguraci kamery hry" }
L["First person inside the game's own camera (the camera patch, IRIDIUM\\fp_camera): native mouse, walking and aiming"] = { "Prima persona nella telecamera stessa del gioco (la patch della telecamera, IRIDIUM\\fp_camera): mouse, camminata e mira nativi", "Primeira pessoa na própria câmera do jogo (o patch de câmera, IRIDIUM\\fp_camera): mouse, andar e mira nativos", "Pierwsza osoba w samej kamerze gry (łatka kamery, IRIDIUM\\fp_camera): natywna mysz, chód i celowanie", "Oyunun kendi kamerasında birinci şahıs (kamera yaması, IRIDIUM\\fp_camera): doğal fare, yürüme ve nişan", "První osoba přímo v kameře hry (patch kamery, IRIDIUM\\fp_camera): nativní myš, chůze a míření" }
L["First-person: turn the view on, then check"] = { "Prima persona: prima attiva la visuale, poi controlla", "Primeira pessoa: ligue a visão primeiro, depois verifique", "Pierwsza osoba: najpierw włącz widok, potem sprawdzaj", "Birinci şahıs: önce görünümü aç, sonra kontrol et", "První osoba: nejdřív zapni pohled, pak kontroluj" }
L["Without the game camera config, and in vehicles. Head camera: held at the eyes. Game camera: the game's own, stops just behind the head on foot"] = { "Senza la config della telecamera del gioco, e nei veicoli. Nella testa: tenuta agli occhi. Del gioco: quella originale, a piedi si ferma appena dietro la testa", "Sem a config de câmera do jogo, e em veículos. Na cabeça: presa aos olhos. Do jogo: a original, a pé para logo atrás da cabeça", "Bez konfiguracji kamery gry i w pojazdach. W głowie: trzymana przy oczach. Kamera gry: własna, pieszo zatrzymuje się tuż za głową", "Oyunun kamera ayarı olmadan ve araçlarda. Kafa kamerası: gözlerde tutulur. Oyun kamerası: oyunun kendisi, yürürken kafanın hemen arkasında durur", "Bez konfigurace kamery hry a ve vozidlech. V hlavě: držená u očí. Kamera hry: vlastní, pěšky se zastaví těsně za hlavou" }
L["Only without the game camera config (with it vehicles always use the head camera). Head camera: held at the eyes. Game camera: the game's own, stops just behind the head on foot"] = { "Solo senza la config della telecamera del gioco (con essa nei veicoli sempre la telecamera nella testa). Nella testa: tenuta agli occhi. Del gioco: quella originale, a piedi si ferma appena dietro la testa", "Só sem a config de câmera do jogo (com ela, em veículos sempre a câmera na cabeça). Na cabeça: presa aos olhos. Do jogo: a original, a pé para logo atrás da cabeça", "Tylko bez konfiguracji kamery gry (z nią w pojazdach zawsze kamera w głowie). W głowie: trzymana przy oczach. Kamera gry: własna, pieszo zatrzymuje się tuż za głową", "Sadece oyunun kamera ayarı olmadan (onunla araçlarda hep kafa kamerası). Kafa kamerası: gözlerde tutulur. Oyun kamerası: oyunun kendisi, yürürken kafanın hemen arkasında durur", "Jen bez konfigurace kamery hry (s ní ve vozidlech vždy kamera v hlavě). V hlavě: držená u očí. Kamera hry: vlastní, pěšky se zastaví těsně za hlavou" }
L["On foot without the game camera config: keeps the camera from trailing the head while running; never used in vehicles"] = { "A piedi senza la config della telecamera del gioco: evita che la telecamera resti indietro in corsa; mai usato nei veicoli", "A pé sem a config de câmera do jogo: evita que a câmera fique atrás da cabeça ao correr; nunca usado em veículos", "Pieszo bez konfiguracji kamery gry: żeby w biegu kamera nie zostawała za głową; w pojazdach nieużywane", "Yürürken oyunun kamera ayarı olmadan: koşarken kameranın kafanın gerisinde kalmasını önler; araçlarda hiç kullanılmaz", "Pěšky bez konfigurace kamery hry: aby kamera při běhu nezaostávala za hlavou; ve vozidlech se nepoužívá" }
L["Field of view in vehicles"] = { "Campo visivo nei veicoli", "Campo de visão em veículos", "Pole widzenia w pojeździe", "Araçta görüş açısı", "Zorné pole ve vozidle" }
L["Wider in a car for the sense of speed; on foot the angle stays the game's"] = { "Più ampio in auto per la sensazione di velocità; a piedi resta l'angolo del gioco", "Mais aberto no carro para a sensação de velocidade; a pé fica o ângulo do jogo", "W aucie szerzej dla poczucia prędkości; pieszo kąt zostaje jak w grze", "Hız hissi için arabada daha geniş; yürürken açı oyunun kendisi kalır", "V autě širší pro pocit rychlosti; pěšky zůstává úhel hry" }
L["Game keeps the game's own angle, aiming zoom included; with the game camera config it is always the game's"] = { "«Come nel gioco» tiene l'angolo originale, zoom di mira compreso; con la config della telecamera è sempre quello del gioco", "“Como no jogo” mantém o ângulo original, zoom da mira incluído; com a config de câmera é sempre o do jogo", "„Jak w grze” zostawia własny kąt razem z przybliżeniem celownika; z konfiguracją kamery gry kąt jest zawsze jak w grze", "“Oyundaki gibi” oyunun kendi açısını korur, nişan yakınlaştırması dahil; kamera ayarıyla açı her zaman oyunun kendisidir", "„Jako ve hře“ ponechá vlastní úhel i s přiblížením mířidel; s konfigurací kamery hry je úhel vždy herní" }
L["How fast the head camera turns with the mouse: in vehicles, and on foot in the head camera mode without the game camera config. Elsewhere the game's own mouse setting applies"] = { "Quanto velocemente la telecamera nella testa gira col mouse: nei veicoli, e a piedi in modalità telecamera nella testa senza la config della telecamera. Altrove vale l'impostazione del mouse del gioco", "Quão rápido a câmera na cabeça gira com o mouse: em veículos, e a pé no modo câmera na cabeça sem a config de câmera. No resto vale a configuração de mouse do próprio jogo", "Szybkość obrotu kamery w głowie myszą: w pojazdach i pieszo w trybie „Kamera w głowie” bez konfiguracji kamery gry. W pozostałych przypadkach działa ustawienie myszy samej gry", "Kafa kamerasının fareyle dönme hızı: araçlarda ve oyunun kamera ayarı olmadan kafa kamerası modunda yürürken. Diğer durumlarda oyunun kendi fare ayarı geçerlidir", "Rychlost otáčení kamery v hlavě myší: ve vozidlech a pěšky v režimu „Kamera v hlavě“ bez konfigurace kamery hry. Jinde platí nastavení myši samotné hry" }
L["Off keeps the view steady. On foot: the eyes' up and down while walking (not with a gun in hand, in cover or a fight). In a vehicle: the driver's head"] = { "No mantiene la vista ferma. A piedi: il su e giù degli occhi camminando (non con un'arma in mano, in copertura o in una rissa). In un veicolo: la testa del guidatore", "Não mantém a visão estável. A pé: o sobe e desce dos olhos ao andar (não com arma na mão, na cobertura ou numa briga). No veículo: a cabeça do motorista", "Wył. — widok się nie kołysze. Pieszo: oczy idą w górę i w dół podczas chodzenia (poza bronią w ręku, osłoną i bójką). W aucie: ruchy głowy kierowcy", "Kapalı görüşü sabit tutar. Yürürken: yürüyüşte gözlerin inip kalkması (elde silah, siperde veya kavgada değil). Araçta: sürücünün kafası", "Vyp. drží pohled klidný. Pěšky: pohyb očí nahoru a dolů při chůzi (ne se zbraní v ruce, v krytu ani ve rvačce). Ve vozidle: hlava řidiče" }
L["On foot. With the game camera config also with a gun from the hip; in the sights the zoom is the game's"] = { "A piedi. Con la config della telecamera anche con un'arma all'anca; in mira lo zoom è quello del gioco", "A pé. Com a config de câmera também com arma no quadril; na mira o zoom é o do jogo", "Pieszo. Z konfiguracją kamery gry także z bronią od biodra; w celowniku przybliżenie jak w grze", "Yürürken. Oyunun kamera ayarıyla belden silahla da; nişangâhta yakınlaştırma oyunun kendisidir", "Pěšky. S konfigurací kamery hry i se zbraní od boku; v mířidlech je přiblížení herní" }
L["Wider in a car for the sense of speed; on foot the field of view above applies"] = { "Più ampio in auto per la sensazione di velocità; a piedi vale il campo visivo sopra", "Mais aberto no carro para a sensação de velocidade; a pé vale o campo de visão acima", "W aucie szerzej dla poczucia prędkości; pieszo działa pole widzenia powyżej", "Hız hissi için arabada daha geniş; yürürken yukarıdaki görüş açısı geçerlidir", "V autě širší pro pocit rychlosti; pěšky platí zorné pole výše" }
L["Head camera on foot (without the game camera config, which places the camera itself): metres in front of the eyes; more if you see the inside of the head"] = { "Telecamera nella testa a piedi (senza la config della telecamera, che piazza la telecamera da sé): metri davanti agli occhi; di più se vedi l'interno della testa", "Câmera na cabeça a pé (sem a config de câmera, que posiciona a câmera sozinha): metros à frente dos olhos; mais se você vir o interior da cabeça", "Kamera w głowie pieszo (bez konfiguracji kamery gry, która sama ustawia kamerę): metry przed oczami; dodaj, jeśli widać głowę od środka", "Yürürken kafa kamerası (kamerayı kendisi yerleştiren oyun kamera ayarı olmadan): gözlerin önündeki metre; kafanın içi görünüyorsa artır", "Kamera v hlavě pěšky (bez konfigurace kamery hry, která kameru umístí sama): metry před očima; přidej, pokud je vidět hlava zevnitř" }
L["Camera forward in vehicles"] = { "Telecamera avanti nei veicoli", "Câmera à frente em veículos", "Kamera do przodu w pojeździe", "Araçta kamera ileri", "Kamera dopředu ve vozidle" }
L["Metres in front of the driver's eyes, minus behind them; more if you see the inside of the head"] = { "Metri davanti agli occhi del guidatore, meno dietro; di più se vedi l'interno della testa", "Metros à frente dos olhos do motorista, menos atrás; mais se você vir o interior da cabeça", "Metry przed oczami kierowcy, minus — za nimi; dodaj, jeśli widać głowę od środka", "Sürücünün gözlerinin önündeki metre, eksi arkası; kafanın içi görünüyorsa artır", "Metry před očima řidiče, minus za nimi; přidej, pokud je vidět hlava zevnitř" }
L["Metres above or below the eyes, on foot and in vehicles"] = { "Metri sopra o sotto gli occhi, a piedi e nei veicoli", "Metros acima ou abaixo dos olhos, a pé e em veículos", "Metry powyżej lub poniżej oczu, pieszo i w pojazdach", "Gözlerin üstünde veya altında metre, yürürken ve araçta", "Metry nad nebo pod očima, pěšky i ve vozidlech" }
L["Smooth steps"] = { "Scalini morbidi", "Suavizar degraus", "Wygładzaj schody", "Basamakları yumuşat", "Vyhlazovat schody" }
L["With the game camera config: on stairs the camera rises and sinks smoothly instead of jumping with the feet (at most 12 cm behind)"] = { "Con la config della telecamera: sulle scale la telecamera sale e scende morbida invece di saltare coi piedi (al massimo 12 cm di ritardo)", "Com a config de câmera: na escada a câmera sobe e desce suave em vez de pular com os pés (no máximo 12 cm atrás)", "Z konfiguracją kamery gry: na schodach kamera wznosi się i opada płynnie, zamiast skakać razem ze stopami (opóźnienie najwyżej 12 cm)", "Oyunun kamera ayarıyla: merdivende kamera ayaklarla zıplamak yerine yumuşakça iner ve çıkar (en fazla 12 cm geride)", "S konfigurací kamery hry: na schodech kamera stoupá a klesá plynule, místo aby skákala s nohama (zpoždění nejvýš 12 cm)" }
L["Camera with a gun: right"] = { "Telecamera con arma: destra", "Câmera com arma: direita", "Kamera z bronią: w prawo", "Silahla kamera: sağa", "Kamera se zbraní: vpravo" }
L["Camera with a gun: down"] = { "Telecamera con arma: giù", "Câmera com arma: baixo", "Kamera z bronią: w dół", "Silahla kamera: aşağı", "Kamera se zbraní: dolů" }
L["With the game camera config and a gun in hand, not aiming down the sights: metres to the right toward the weapon, so it is in view. Needs the current ASI (right mouse button = aiming)"] = { "Con la config della telecamera e un'arma in mano, senza mirare: metri a destra verso l'arma, perché sia in vista. Serve l'ASI aggiornato (tasto destro = mira)", "Com a config de câmera e uma arma na mão, sem mirar: metros para a direita em direção à arma, para ela aparecer. Precisa do ASI atual (botão direito = mira)", "Z konfiguracją kamery gry, z bronią w ręku, bez celowania: o ile metrów kamera idzie w prawo do broni, żeby była widoczna. Wymaga aktualnego ASI (prawy przycisk myszy = celowanie)", "Oyunun kamera ayarı ve elde silahla, nişan almadan: silahın görünmesi için silaha doğru sağa metre. Güncel ASI gerekli (sağ fare tuşu = nişan)", "S konfigurací kamery hry a zbraní v ruce, bez míření: o kolik metrů se kamera posune vpravo ke zbrani, aby byla vidět. Vyžaduje aktuální ASI (pravé tlačítko myši = míření)" }
L["Camera in the sights: right"] = { "Telecamera in mira: destra", "Câmera na mira: direita", "Kamera w celowniku: w prawo", "Nişangâhta kamera: sağa", "Kamera v mířidlech: vpravo" }
L["Camera in the sights: down"] = { "Telecamera in mira: giù", "Câmera na mira: baixo", "Kamera w celowniku: w dół", "Nişangâhta kamera: aşağı", "Kamera v mířidlech: dolů" }
L["With the game camera config, aiming down the sights (right mouse button): metres to the right, on top of the config's place for each weapon; minus is to the left. Needs the current ASI"] = { "Con la config della telecamera, mirando (tasto destro): metri a destra, oltre al posto della config per ogni arma; meno è a sinistra. Serve l'ASI aggiornato", "Com a config de câmera, mirando (botão direito): metros para a direita, além do lugar da config para cada arma; menos é para a esquerda. Precisa do ASI atual", "Z konfiguracją kamery gry, w celowniku (prawy przycisk myszy): o ile metrów w prawo, ponad miejsce z konfiguracji dla każdej broni; minus — w lewo. Wymaga aktualnego ASI", "Oyunun kamera ayarıyla, nişan alırken (sağ fare tuşu): her silah için ayardaki yerin üstüne sağa metre; eksi sola. Güncel ASI gerekli", "S konfigurací kamery hry, při míření (pravé tlačítko myši): o kolik metrů vpravo, navíc k místu z konfigurace pro každou zbraň; minus je vlevo. Vyžaduje aktuální ASI" }
L["Aiming down the sights: metres down; minus is up"] = { "Mirando: metri in giù; meno è in su", "Mirando: metros para baixo; menos é para cima", "W celowniku: o ile metrów w dół; minus — w górę", "Nişan alırken: aşağı metre; eksi yukarı", "Při míření: o kolik metrů dolů; minus je nahoru" }
L["With a gun in hand, not aiming down the sights: metres down toward the weapon"] = { "Con un'arma in mano, senza mirare: metri in giù verso l'arma", "Com uma arma na mão, sem mirar: metros para baixo em direção à arma", "Z bronią w ręku, bez celowania: o ile metrów kamera opada do broni", "Elde silahla, nişan almadan: silaha doğru aşağı metre", "Se zbraní v ruce, bez míření: o kolik metrů kamera klesne ke zbrani" }
L["Hide the body when the head is ahead of the camera"] = { "Nascondi il corpo quando la testa è davanti alla telecamera", "Esconder o corpo quando a cabeça fica à frente da câmera", "Ukrywaj ciało, gdy głowa jest przed kamerą", "Kafa kameranın önündeyken vücudu gizle", "Skrýt tělo, když je hlava před kamerou" }
L["With the game camera config: starting off sharply, crouching and getting up, Lincoln's head leans ahead of the camera, which cannot move forward, and his eyes and mouth would show from inside. On: the body is hidden for that moment. Off: it stays"] = {
	"Con la config della telecamera: partendo di scatto, accovacciandosi e rialzandosi, la testa di Lincoln va davanti alla telecamera, che non può avanzare, e si vedrebbero gli occhi e la bocca dall'interno. Sì: il corpo si nasconde per quell'attimo. No: resta",
	"Com a config de câmera: ao arrancar de repente, agachar e levantar, a cabeça do Lincoln passa à frente da câmera, que não pode avançar, e daria para ver olhos e boca por dentro. Sim: o corpo some nesse instante. Não: ele fica",
	"Z konfiguracją kamery gry: przy gwałtownym ruszeniu, kucaniu i wstawaniu głowa Lincolna wychodzi przed kamerę, której nie da się przesunąć do przodu, i od środka byłyby widoczne oczy i usta. Wł. — ciało na tę chwilę się chowa. Wył. — zostaje",
	"Oyunun kamera ayarıyla: aniden harekete geçerken, çömelirken ve kalkarken Lincoln'ün kafası öne çıkamayan kameranın önüne geçer ve gözler ile ağız içeriden görünürdü. Açık: vücut o an gizlenir. Kapalı: kalır",
	"S konfigurací kamery hry: při prudkém rozjezdu, přikrčení a vstávání se Lincolnova hlava dostane před kameru, kterou nejde posunout dopředu, a zevnitř by byly vidět oči a ústa. Zap.: tělo se na ten okamžik skryje. Vyp.: zůstane" }
L["First-person view is on (F4 - Camera turns it off)"] = { "Prima persona attiva (disattivare: F4 — Telecamera)", "Primeira pessoa ligada (desligar: F4 — Câmera)", "Widok z pierwszej osoby włączony (wyłączanie: F4 — Kamera)", "Birinci şahıs açık (kapatmak için: F4 — Kamera)", "Pohled z první osoby zapnut (vypnutí: F4 — Kamera)" }
L["Takedowns in first person"] = { "Eliminazioni in prima persona", "Eliminações em primeira pessoa", "Eliminacje z pierwszej osoby", "Birinci şahıs infazlar", "Likvidace z první osoby" }
L["Quiet ones"] = { "Silenziose", "Silenciosas", "Ciche", "Sessiz olanlar", "Tiché" }
L["Quiet and stunned"] = { "Silenziose e storditi", "Silenciosas e atordoados", "Ciche i ogłuszeni", "Sessiz ve sersemlemiş", "Tiché a omráčení" }
L["All but the brutal (experimental)"] = { "Tutte tranne le brutali (sperimentale)", "Todas menos as brutais (experimental)", "Wszystkie oprócz brutalnych (eksperyment)", "Vahşiler hariç hepsi (deneysel)", "Všechny kromě brutálních (pokus)" }
L["With the game camera config: the camera stays at the eyes in a takedown from behind, of a seated man, of one on the phone or at a mounted gun. With stunned: also finishing a stunned one (a civilian after a beating too). All but the brutal (experimental): also from cover, over cover, on the run and of a man on the floor. The brutal ones keep the game's camera. Needs the current ASI"] = {
	"Con la config della telecamera: la telecamera resta agli occhi in un'eliminazione alle spalle, di un uomo seduto, al telefono o a una mitragliatrice. Con storditi: anche finire uno stordito (anche un civile dopo una rissa). Tutte tranne le brutali (sperimentale): anche dalla copertura, oltre la copertura, in corsa e di un uomo a terra. Le brutali tengono la telecamera del gioco. Serve l'ASI aggiornato",
	"Com a config de câmera: a câmera fica nos olhos numa eliminação pelas costas, de alguém sentado, ao telefone ou numa metralhadora. Com atordoados: também finalizar um atordoado (também um civil após uma briga). Todas menos as brutais (experimental): também da cobertura, por cima da cobertura, correndo e de alguém no chão. As brutais mantêm a câmera do jogo. Precisa do ASI atual",
	"Z konfiguracją kamery gry: kamera zostaje przy oczach przy eliminacji od tyłu, siedzącego, rozmawiającego przez telefon lub stojącego przy karabinie maszynowym. „Ciche i ogłuszeni” — także dobicie ogłuszonego (i cywila po bójce). „Wszystkie oprócz brutalnych” (eksperyment) — także zza osłony, przez osłonę, z rozbiegu i leżącego na ziemi. Brutalne pokazuje kamera gry. Wymaga aktualnego ASI",
	"Oyunun kamera ayarıyla: arkadan, oturan birine, telefonla konuşana veya makineli tüfek başındakine yapılan infazda kamera gözlerde kalır. Sersemlemişlerle: sersemlemiş birini bitirmek de (kavgadan sonra bir sivili de). Vahşiler hariç hepsi (deneysel): siperden, siperin üzerinden, koşarken ve yerdeki birine de. Vahşiler oyunun kamerasıyla kalır. Güncel ASI gerekli",
	"S konfigurací kamery hry: kamera zůstane u očí při likvidaci zezadu, sedícího, telefonujícího nebo u kulometu. „Tiché a omráčení“ — i dorážení omráčeného (i civilisty po rvačce). „Všechny kromě brutálních“ (pokus) — i z krytu, přes kryt, v běhu a ležícího na zemi. Brutální ukazuje kamera hry. Vyžaduje aktuální ASI" }
L["View on foot"] = { "Visuale a piedi", "Visão a pé", "Widok pieszo", "Yürürken görünüm", "Pohled pěšky" }
L["First person"] = { "Prima persona", "Primeira pessoa", "Pierwsza osoba", "Birinci şahıs", "První osoba" }
L["Third person"] = { "Terza persona", "Terceira pessoa", "Trzecia osoba", "Üçüncü şahıs", "Třetí osoba" }
L["Third person: with the camera patch the camera moves back behind Lincoln's shoulder on the fly (mouse, walking and aiming stay the game's). Without the patch it is the game's own camera on foot and first person in vehicles only, the patch is not needed for that. The view key switches it"] = {
	"Terza persona: con la patch della telecamera, la telecamera arretra al volo dietro la spalla di Lincoln (mouse, camminata e mira restano del gioco). Senza la patch a piedi la telecamera del gioco e la prima persona solo nei veicoli, la patch non serve per questo. Il tasto visuale la cambia",
	"Terceira pessoa: com o patch de câmera, a câmera recua na hora para trás do ombro do Lincoln (mouse, andar e mira continuam do jogo). Sem o patch, a pé a câmera do próprio jogo e a primeira pessoa só em veículos, para isso o patch não é necessário. A tecla de visão alterna",
	"Trzecia osoba: z łatką kamery kamera w locie odjeżdża za ramię Lincolna (mysz, chód i celowanie zostają z gry). Bez łatki pieszo własna kamera gry, a pierwsza osoba tylko w aucie — do tego łatka nie jest potrzebna. Przełącza też klawisz widoku",
	"Üçüncü şahıs: kamera yamasıyla kamera anında Lincoln'ün omzunun arkasına çekilir (fare, yürüme ve nişan oyunun kendisi kalır). Yama olmadan yürürken oyunun kendi kamerası, birinci şahıs sadece araçlarda; bunun için yama gerekmez. Görünüm tuşu değiştirir",
	"Třetí osoba: s patchem kamery kamera za jízdy odjede za Lincolnovo rameno (myš, chůze a míření zůstávají herní). Bez patche pěšky vlastní kamera hry a první osoba jen ve vozidlech — k tomu patch není potřeba. Přepíná i klávesa pohledu" }
L["First-person view is on in vehicles; on foot the game's camera (F4 - Camera)"] = { "Prima persona attiva nei veicoli; a piedi la telecamera del gioco (F4 — Telecamera)", "Primeira pessoa ligada em veículos; a pé a câmera do jogo (F4 — Câmera)", "Widok z pierwszej osoby włączony w aucie; pieszo kamera gry (F4 — Kamera)", "Birinci şahıs araçlarda açık; yürürken oyunun kamerası (F4 — Kamera)", "Pohled z první osoby zapnut ve vozidle; pěšky kamera hry (F4 — Kamera)" }
L["Camera follows the driver's lean"] = { "La telecamera segue l'inclinazione del guidatore", "A câmera segue a inclinação do motorista", "Kamera za pochyleniem kierowcy", "Kamera sürücünün eğilmesini izler", "Kamera sleduje náklon řidiče" }
L["The camera at the driver's eyes is fixed to the seat. Leaning forward (braking, a turn) his head came in front of it. On: along the car the camera follows his eyes forward once they are over 4 cm off the seat, without the small shakes"] = {
	"La telecamera agli occhi del guidatore è fissata al sedile. Sporgendosi in avanti (frenata, curva) la sua testa le finiva davanti. Sì: lungo l'auto la telecamera segue i suoi occhi in avanti appena superano i 4 cm dal sedile, senza i piccoli scossoni",
	"A câmera nos olhos do motorista é fixa no banco. Ao se inclinar para frente (freada, curva) a cabeça dele ficava na frente dela. Sim: ao longo do carro a câmera segue os olhos para frente assim que passam de 4 cm do banco, sem os pequenos tremores",
	"Kamera przy oczach kierowcy jest przypięta do fotela. Gdy pochylał się do przodu (hamowanie, zakręt), głowa wchodziła przed kamerę. Wł. — wzdłuż auta kamera idzie za oczami do przodu, gdy tylko są dalej niż 4 cm od fotela, bez drobnych drgań",
	"Sürücünün gözlerindeki kamera koltuğa sabittir. Öne eğildiğinde (fren, viraj) kafası kameranın önüne geçiyordu. Açık: araba boyunca kamera, gözler koltuktan 4 cm'den fazla uzaklaşınca onları öne doğru izler, küçük sarsıntılar olmadan",
	"Kamera u očí řidiče je připevněná k sedadlu. Když se naklonil dopředu (brzdění, zatáčka), hlava se dostala před ni. Zap.: podél auta jde kamera za očima dopředu, jakmile jsou dál než 4 cm od sedadla, bez drobného třesu" }
L["Hide the hat"] = { "Nascondi il cappello", "Esconder o chapéu", "Ukrywaj kapelusz", "Şapkayı gizle", "Skrýt klobouk" }
L["In first person, on foot and at the wheel, Lincoln's hat is hidden: its brim came into the view. Shown again in third person, with the game's camera and when the view is off. Glasses cannot be hidden this way"] = {
	"In prima persona, a piedi e alla guida, il cappello di Lincoln si nasconde: la tesa entrava nella vista. Torna in terza persona, con la telecamera del gioco e quando la visuale è spenta. Gli occhiali non si possono nascondere così",
	"Em primeira pessoa, a pé e ao volante, o chapéu do Lincoln some: a aba entrava na visão. Volta em terceira pessoa, com a câmera do jogo e com a visão desligada. Os óculos não podem ser escondidos assim",
	"Z pierwszej osoby, pieszo i za kierownicą, kapelusz Lincolna się chowa: jego rondo wchodziło w kadr. Wraca w trzeciej osobie, z kamerą gry i przy wyłączonym widoku. Okularów tak nie da się ukryć",
	"Birinci şahısta, yürürken ve direksiyonda Lincoln'ün şapkası gizlenir: kenarı görüşe giriyordu. Üçüncü şahısta, oyun kamerasıyla ve görünüm kapalıyken geri gelir. Gözlükler bu şekilde gizlenemez",
	"V první osobě, pěšky i za volantem, se Lincolnův klobouk skryje: jeho okraj lezl do záběru. Vrátí se ve třetí osobě, s kamerou hry a při vypnutém pohledu. Brýle tak skrýt nejde" }
L["Camera in the sights for"] = { "Telecamera in mira per", "Câmera na mira para", "Kamera w celowniku dla", "Nişangâhta kamera, silah türü", "Kamera v mířidlech pro" }
L["Pistols and revolvers"] = { "Pistole e revolver", "Pistolas e revólveres", "Pistolety i rewolwery", "Tabancalar ve revolverler", "Pistole a revolvery" }
L["Submachine guns"] = { "Mitra", "Submetralhadoras", "Pistolety maszynowe", "Hafif makineli tüfekler", "Samopaly" }
L["Shotguns"] = { "Fucili a pompa", "Escopetas", "Strzelby", "Pompalı tüfekler", "Brokovnice" }
L["Rifles"] = { "Fucili", "Fuzis", "Karabiny", "Tüfekler", "Pušky" }
L["Sniper rifles"] = { "Fucili da cecchino", "Fuzis de precisão", "Karabiny snajperskie", "Keskin nişancı tüfekleri", "Odstřelovací pušky" }
L["Other guns"] = { "Altre armi", "Outras armas", "Inna broń", "Diğer silahlar", "Jiné zbraně" }
L["With the game camera config the place in the sights below is kept for each kind of gun; this row picks the kind the two rows show, at first the one in hand. Move it where the gun does not cover the target"] = {
	"Con la config della telecamera il posto in mira (le due righe sotto) è tenuto per ogni tipo di arma; questa riga sceglie il tipo che mostrano, prima quello in mano. Spostalo dove l'arma non copre il bersaglio",
	"Com a config de câmera o lugar na mira (as duas linhas abaixo) fica salvo para cada tipo de arma; esta linha escolhe o tipo que elas mostram, primeiro o da mão. Mova para onde a arma não cubra o alvo",
	"Z konfiguracją kamery gry miejsce w celowniku (dwa wiersze niżej) jest zapisywane dla każdego rodzaju broni; ten wiersz wybiera, jaki rodzaj pokazują, najpierw broń w ręku. Przesuń tak, żeby broń nie zasłaniała celu",
	"Oyunun kamera ayarıyla nişangâhtaki yer (alttaki iki satır) her silah türü için saklanır; bu satır onların gösterdiği türü seçer, önce eldeki silah. Silah hedefi kapatmayacak şekilde kaydır",
	"S konfigurací kamery hry se místo v mířidlech (dva řádky níže) ukládá pro každý druh zbraně; tento řádek vybírá, který druh ukazují, nejdřív zbraň v ruce. Posuň tak, aby zbraň nezakrývala cíl" }
L["View key"] = { "Tasto visuale", "Tecla de visão", "Klawisz widoku", "Görünüm tuşu", "Klávesa pohledu" }
L["Switches first and third person where you are: on foot the row above, in a vehicle «Also in vehicles»; turns the view on when it is off. Needs the current ASI"] = {
	"Cambia tra prima e terza persona dove sei: a piedi la riga sopra, in un veicolo «Anche nei veicoli»; accende la visuale se è spenta. Serve l'ASI aggiornato",
	"Alterna entre primeira e terceira pessoa onde você está: a pé a linha acima, no veículo “Também em veículos”; liga a visão se estiver desligada. Precisa do ASI atual",
	"Przełącza pierwszą i trzecią osobę tam, gdzie jesteś: pieszo wiersz wyżej, w aucie „Także w pojazdach”; jeśli widok jest wyłączony, włącza go. Wymaga aktualnego ASI",
	"Bulunduğun yerde birinci ve üçüncü şahıs arasında geçiş yapar: yürürken üstteki satır, araçta “Araçlarda da”; görünüm kapalıysa açar. Güncel ASI gerekli",
	"Přepíná první a třetí osobu tam, kde právě jsi: pěšky řádek výše, ve vozidle „I ve vozidlech“; je-li pohled vypnutý, zapne ho. Vyžaduje aktuální ASI" }
L["Look back in a vehicle"] = { "Guarda indietro nel veicolo", "Olhar para trás no veículo", "Spójrz do tyłu w pojeździe", "Araçta arkaya bak", "Pohled dozadu ve vozidle" }
L["Mouse 3"] = { "Rotella del mouse", "Roda do mouse", "Kółko myszy", "Fare tekerleği", "Kolečko myši" }
L["Hold the key to look back over your shoulder from the driver's seat. Needs the current ASI"] = {
	"Tieni premuto il tasto per guardare indietro oltre la spalla dal posto di guida. Serve l'ASI aggiornato",
	"Segure a tecla para olhar para trás por cima do ombro do banco do motorista. Precisa do ASI atual",
	"Gdy klawisz jest wciśnięty, wzrok z fotela kierowcy obraca się do tyłu przez ramię. Wymaga aktualnego ASI",
	"Sürücü koltuğundan omzunun üzerinden arkaya bakmak için tuşu basılı tut. Güncel ASI gerekli",
	"Dokud držíš klávesu, pohled z místa řidiče se otočí dozadu přes rameno. Vyžaduje aktuální ASI" }
L["Camera in vehicles"] = { "Telecamera nei veicoli", "Câmera em veículos", "Kamera w pojeździe", "Araçta kamera", "Kamera ve vozidle" }
L["At the driver's eyes"] = { "Agli occhi del guidatore", "Nos olhos do motorista", "Przy oczach kierowcy", "Sürücünün gözlerinde", "U očí řidiče" }
L["On the hood"] = { "Sul cofano", "No capô", "Na masce", "Kaputun üstünde", "Na kapotě" }
L["At the driver's eyes, or on the hood (experimental: the hood is longer or shorter by car)"] = {
	"Agli occhi del guidatore o sul cofano (sperimentale: il cofano è più lungo o più corto a seconda dell'auto)",
	"Nos olhos do motorista ou no capô (experimental: o capô é mais longo ou mais curto conforme o carro)",
	"Przy oczach kierowcy lub na masce (eksperyment: długość maski zależy od auta)",
	"Sürücünün gözlerinde veya kaputun üstünde (deneysel: kaput arabaya göre daha uzun ya da kısa)",
	"U očí řidiče nebo na kapotě (pokus: kapota je podle auta delší nebo kratší)" }
L["Preset"] = { "Preset", "Predefinição", "Preset", "Hazır ayar", "Předvolba" }
L["Choose"] = { "Scegli", "Escolher", "Wybierz", "Seç", "Vybrat" }
L["Standard"] = { "Standard", "Padrão", "Standard", "Standart", "Standard" }
L["Steady"] = { "Stabile", "Estável", "Bez kołysania", "Sabit", "Klidný" }
L["Immersive"] = { "Immersivo", "Imersivo", "Immersyjny", "Sürükleyici", "Pohlcující" }
L["Several rows at once. Standard: low head bob, light effects. Steady: no head bob, no effects. Immersive: full head bob, strong effects"] = {
	"Più righe insieme. Standard: oscillazione bassa, effetti leggeri. Stabile: senza oscillazione né effetti. Immersivo: oscillazione piena, effetti forti",
	"Várias linhas de uma vez. Padrão: balanço baixo, efeitos leves. Estável: sem balanço nem efeitos. Imersivo: balanço completo, efeitos fortes",
	"Kilka wierszy naraz. Standard — słabe kołysanie i słabe efekty. Bez kołysania — bez kołysania i efektów. Immersyjny — pełne kołysanie i mocne efekty",
	"Birkaç satır birden. Standart: düşük sallanma, hafif efektler. Sabit: sallanma ve efekt yok. Sürükleyici: tam sallanma, güçlü efektler",
	"Několik řádků najednou. Standard: slabé pohupování, slabé efekty. Klidný: bez pohupování a efektů. Pohlcující: plné pohupování, silné efekty" }
L["Camera effects"] = { "Effetti della telecamera", "Efeitos de câmera", "Efekty kamery", "Kamera efektleri", "Efekty kamery" }
L["Light"] = { "Leggeri", "Leves", "Słabe", "Hafif", "Slabé" }
L["Strong"] = { "Forti", "Fortes", "Mocne", "Güçlü", "Silné" }
L["With the game camera config, in first person: a kick of the camera on each shot (stronger for shotguns, rifles and revolvers), a slow sway in the sights, a dip on landing after a fall"] = {
	"Con la config della telecamera, in prima persona: un sobbalzo della telecamera a ogni colpo (più forte per fucili a pompa, fucili e revolver), un lento ondeggiare in mira, un affondo all'atterraggio dopo una caduta",
	"Com a config de câmera, em primeira pessoa: um tranco da câmera a cada tiro (mais forte com escopetas, fuzis e revólveres), um balanço lento na mira, uma afundada ao aterrissar após uma queda",
	"Z konfiguracją kamery gry, z pierwszej osoby: szarpnięcie kamery przy każdym strzale (mocniejsze przy strzelbach, karabinach i rewolwerach), lekkie kołysanie w celowniku, przysiad przy lądowaniu po upadku",
	"Oyunun kamera ayarıyla, birinci şahısta: her atışta kamerada sarsıntı (pompalı, tüfek ve revolverde daha güçlü), nişangâhta yavaş salınım, düştükten sonra yere inişte çökme",
	"S konfigurací kamery hry, v první osobě: cuknutí kamery při každém výstřelu (silnější u brokovnic, pušek a revolverů), pomalé pohupování v mířidlech, propad při dopadu po pádu" }
L["Camera follows the head in cover"] = { "La telecamera segue la testa in copertura", "A câmera segue a cabeça na cobertura", "Kamera za głową w osłonie", "Siperde kamera kafayı izler", "Kamera sleduje hlavu v krytu" }
L["With the game camera config: peeking out of cover and ducking, the camera goes with the head sideways and in height"] = {
	"Con la config della telecamera: sporgendosi dalla copertura e abbassandosi, la telecamera segue la testa di lato e in altezza",
	"Com a config de câmera: ao espiar da cobertura e se abaixar, a câmera segue a cabeça para o lado e na altura",
	"Z konfiguracją kamery gry: gdy Lincoln wychyla się z osłony lub się kuli, kamera idzie za głową w bok i w pionie",
	"Oyunun kamera ayarıyla: siperden bakarken ve eğilirken kamera kafayı yana ve yükseklikte izler",
	"S konfigurací kamery hry: když Lincoln vykukuje z krytu nebo se krčí, kamera jde za hlavou do strany i výšky" }
L["First-person: third person on foot does not work here (the camera does not move back); first person stays"] = {
	"Prima persona: la terza persona a piedi qui non funziona (la telecamera non arretra); resta la prima persona",
	"Primeira pessoa: a terceira pessoa a pé não funciona aqui (a câmera não recua); fica a primeira pessoa",
	"Pierwsza osoba: trzecia osoba pieszo tu nie działa (kamera nie odjeżdża do tyłu), zostaje pierwsza",
	"Birinci şahıs: yürürken üçüncü şahıs burada çalışmıyor (kamera geri çekilmiyor); birinci şahıs kalır",
	"První osoba: třetí osoba pěšky tady nefunguje (kamera neodjede dozadu), zůstává první" }
L["First-person view: first person in vehicles"] = { "Visuale: prima persona nei veicoli", "Visão: primeira pessoa no veículo", "Widok: pierwsza osoba w aucie", "Görünüm: araçta birinci şahıs", "Pohled: první osoba ve vozidle" }
L["First-person view: the game's camera in vehicles"] = { "Visuale: telecamera del gioco nei veicoli", "Visão: câmera do jogo no veículo", "Widok: kamera gry w aucie", "Görünüm: araçta oyunun kamerası", "Pohled: kamera hry ve vozidle" }
L["First-person view: third person on foot"] = { "Visuale a piedi: terza persona", "Visão a pé: terceira pessoa", "Widok pieszo: trzecia osoba", "Yürürken görünüm: üçüncü şahıs", "Pohled pěšky: třetí osoba" }
L["First-person view: first person on foot"] = { "Visuale a piedi: prima persona", "Visão a pé: primeira pessoa", "Widok pieszo: pierwsza osoba", "Yürürken görünüm: birinci şahıs", "Pohled pěšky: první osoba" }
L["First-person: preset applied"] = { "Prima persona: preset applicato", "Primeira pessoa: predefinição aplicada", "Pierwsza osoba: preset zastosowany", "Birinci şahıs: hazır ayar uygulandı", "První osoba: předvolba použita" }
L["On foot. With the game camera config also with a gun from the hip; in the sights the next row applies"] = { "A piedi. Con la config della telecamera anche con un'arma all'anca; in mira vale la riga successiva", "A pé. Com a config de câmera também com arma no quadril; na mira vale a linha seguinte", "Pieszo. Z konfiguracją kamery gry także z bronią od biodra; w celowniku działa wiersz niżej", "Yürürken. Oyunun kamera ayarıyla belden silahla da; nişangâhta sonraki satır geçerlidir", "Pěšky. S konfigurací kamery hry i se zbraní od boku; v mířidlech platí řádek níže" }
L["Field of view in the sights"] = { "Campo visivo in mira", "Campo de visão na mira", "Pole widzenia w celowniku", "Nişangâhta görüş açısı", "Zorné pole v mířidlech" }
L["On foot"] = { "Come a piedi", "Como a pé", "Jak pieszo", "Yürürkenki gibi", "Jako pěšky" }
L["With the game camera config, aiming down the sights (right mouse button). Game: the config's zoom for each weapon; On foot: no zoom, the angle above"] = {
	"Con la config della telecamera, mirando (tasto destro). «Come nel gioco»: lo zoom della config per ogni arma; «Come a piedi»: niente zoom, l'angolo sopra",
	"Com a config de câmera, mirando (botão direito). “Como no jogo”: o zoom da config para cada arma; “Como a pé”: sem zoom, o ângulo acima",
	"Z konfiguracją kamery gry, w celowniku (prawy przycisk myszy). „Jak w grze” — przybliżenie z konfiguracji dla każdej broni; „Jak pieszo” — bez przybliżenia, kąt z wiersza wyżej",
	"Oyunun kamera ayarıyla, nişan alırken (sağ fare tuşu). “Oyundaki gibi”: her silah için ayardaki yakınlaştırma; “Yürürkenki gibi”: yakınlaştırma yok, yukarıdaki açı",
	"S konfigurací kamery hry, při míření (pravé tlačítko myši). „Jako ve hře“: přiblížení z konfigurace pro každou zbraň; „Jako pěšky“: bez přiblížení, úhel z řádku výše" }
L["Only without the game camera config: switch it if at speed the camera trails the head or runs ahead. The head camera in a vehicle never uses it"] = {
	"Solo senza la config della telecamera: cambialo se in velocità la telecamera resta indietro o va avanti. La telecamera nella testa nei veicoli non lo usa mai",
	"Só sem a config de câmera: mude se em velocidade a câmera fica atrás da cabeça ou se adianta. A câmera na cabeça no veículo nunca usa isso",
	"Tylko bez konfiguracji kamery gry: przełącz, jeśli przy prędkości kamera zostaje za głową lub ucieka do przodu. Kamera w głowie w pojeździe tego nie używa",
	"Sadece oyunun kamera ayarı olmadan: hızda kamera kafanın gerisinde kalıyor veya öne kaçıyorsa değiştir. Araçtaki kafa kamerası bunu hiç kullanmaz",
	"Jen bez konfigurace kamery hry: přepni, pokud při rychlosti kamera zaostává za hlavou nebo utíká dopředu. Kamera v hlavě ve vozidle to nepoužívá" }

-- player
L["Change Model"] = { "Cambia aspetto", "Mudar visual", "Zmień wygląd", "Görünümü değiştir", "Změnit vzhled" }
L["Search"] = { "Cerca", "Buscar", "Szukaj", "Ara", "Hledat" }
L["Start typing to filter"] = { "inizia a scrivere", "digite para filtrar", "zacznij pisać", "filtrelemek için yaz", "začni psát" }
L["Player Tags"] = { "Tag del giocatore", "Tags do jogador", "Tagi gracza", "Oyuncu etiketleri", "Štítky hráče" }
L["Player Info"] = { "Info giocatore", "Info do jogador", "Informacje o graczu", "Oyuncu bilgisi", "Info o hráči" }
L["Noclip"] = { "Noclip", "Noclip", "Noclip", "Noclip", "Noclip" }
L["Noclip Speed"] = { "Velocità di volo", "Velocidade de voo", "Prędkość lotu", "Uçuş hızı", "Rychlost letu" }
L["Vehicle Noclip Speed"] = { "Velocità di volo in auto", "Velocidade de voo no carro", "Prędkość lotu w aucie", "Arabada uçuş hızı", "Rychlost letu v autě" }

-- weapons, weather
L["Give Weapon"] = { "Dai arma", "Dar arma", "Daj broń", "Silah ver", "Dát zbraň" }
L["Set Weather"] = { "Meteo", "Clima", "Pogoda", "Hava", "Počasí" }

-- vehicle parts
L["Vehicle Colors"] = { "Colori della vernice", "Cores da pintura", "Kolory lakieru", "Boya renkleri", "Barvy laku" }
L["Primary Color"] = { "Colore principale", "Cor principal", "Kolor główny", "Ana renk", "Hlavní barva" }
L["Secondary Color"] = { "Colore secondario", "Cor secundária", "Kolor dodatkowy", "İkincil renk", "Druhá barva" }
L["Window Tint and Opacity"] = { "Colore e opacità dei vetri", "Cor e opacidade dos vidros", "Kolor i przezroczystość szyb", "Cam rengi ve opaklığı", "Barva a průhlednost skel" }
L["Vehicle Window Tint"] = { "Vetri oscurati", "Película dos vidros", "Przyciemnienie szyb", "Cam filmi", "Tónování skel" }
L["Choose Front Wheels"] = { "Cerchi anteriori", "Rodas dianteiras", "Przednie felgi", "Ön jantlar", "Přední kola" }
L["Choose Rear Wheels"] = { "Cerchi posteriori", "Rodas traseiras", "Tylne felgi", "Arka jantlar", "Zadní kola" }
L["Enter RGB values separated by spaces. Eg: 255 255 255"] = { "Valori RGB separati da spazi, es. 255 255 255", "Valores RGB separados por espaços, ex. 255 255 255", "Trzy liczby RGB oddzielone spacją, np. 255 255 255", "Boşlukla ayrılmış RGB değerleri, örn. 255 255 255", "Tři čísla RGB oddělená mezerou, např. 255 255 255" }
L["Enter RGBA values separated by spaces. Eg: 255 255 255 255"] = { "Valori RGBA separati da spazi, es. 255 255 255 255", "Valores RGBA separados por espaços, ex. 255 255 255 255", "Cztery liczby RGBA oddzielone spacją, np. 255 255 255 255", "Boşlukla ayrılmış RGBA değerleri, örn. 255 255 255 255", "Čtyři čísla RGBA oddělená mezerou, např. 255 255 255 255" }
L["Enter ammount (0-100)"] = { "Quantità da 0 a 100", "Quantidade de 0 a 100", "Ilość od 0 do 100", "0 ile 100 arası miktar", "Množství od 0 do 100" }
L["Enter multiplier value (Use only integers)"] = { "Moltiplicatore (numero intero)", "Multiplicador (número inteiro)", "Mnożnik (liczba całkowita)", "Çarpan (tam sayı)", "Násobitel (celé číslo)" }
L["Enter rust ammount value (Use only integers)"] = { "Ruggine (numero intero)", "Ferrugem (número inteiro)", "Rdza (liczba całkowita)", "Pas (tam sayı)", "Rez (celé číslo)" }
L["Enter dirt ammount value (Use only integers)"] = { "Sporco (numero intero)", "Sujeira (número inteiro)", "Brud (liczba całkowita)", "Kir (tam sayı)", "Špína (celé číslo)" }
L["Enter custom text (max 5 characters)"] = { "Testo della targa, max 5 caratteri", "Texto da placa, máx. 5 caracteres", "Tekst tablicy, do 5 znaków", "Plaka yazısı, en fazla 5 karakter", "Text SPZ, nejvýš 5 znaků" }
L["Enter steering play value (use only integers)"] = { "Gioco dello sterzo (numero intero)", "Folga da direção (número inteiro)", "Luz kierownicy (liczba całkowita)", "Direksiyon boşluğu (tam sayı)", "Vůle řízení (celé číslo)" }
L["Enter steering offset value (between -45 and 45)"] = { "Disallineamento sterzo tra -45 e 45", "Desvio da direção entre -45 e 45", "Przesunięcie kierownicy od -45 do 45", "-45 ile 45 arası direksiyon kayması", "Posun řízení od -45 do 45" }

-- labels the old trainer builds at run time: prefix = { it, pt, pl, tr, cs }
local P = I18n.More.Prefixes
P["Weapon In Small Slot: "] = { "Slot piccolo: ", "Slot pequeno: ", "Mały slot: ", "Küçük yuva: ", "Malý slot: " }
P["Weapon In Big Slot: "] = { "Slot grande: ", "Slot grande: ", "Duży slot: ", "Büyük yuva: ", "Velký slot: " }
P["Free Camera Enabled: "] = { "Telecamera libera: ", "Câmera livre: ", "Wolna kamera: ", "Serbest kamera: ", "Volná kamera: " }
P["Controls Locked: "] = { "Comandi bloccati: ", "Controles travados: ", "Sterowanie zablokowane: ", "Kontroller kilitli: ", "Ovládání zamčeno: " }
P["Cloth Simulated: "] = { "Simulazione vestiti: ", "Simulação de roupas: ", "Symulacja ubrań: ", "Kıyafet simülasyonu: ", "Simulace oblečení: " }
P["Model Visibile: "] = { "Modello visibile: ", "Modelo visível: ", "Model widoczny: ", "Model görünür: ", "Model viditelný: " }
P["Physics Active: "] = { "Fisica: ", "Física: ", "Fizyka: ", "Fizik: ", "Fyzika: " }
P["Motor Damage: "] = { "Danni al motore: ", "Dano no motor: ", "Uszkodzenie silnika: ", "Motor hasarı: ", "Poškození motoru: " }
P["Front Wheels: "] = { "Cerchi anteriori: ", "Rodas dianteiras: ", "Przednie felgi: ", "Ön jantlar: ", "Přední kola: " }
P["Rear Wheels: "] = { "Cerchi posteriori: ", "Rodas traseiras: ", "Tylne felgi: ", "Arka jantlar: ", "Zadní kola: " }
P["Spawnprofile: "] = { "Profilo: ", "Perfil: ", "Profil: ", "Profil: ", "Profil: " }
P["Voice Hash: "] = { "Voce (hash): ", "Voz (hash): ", "Głos (hash): ", "Ses (hash): ", "Hlas (hash): " }
P["Direction: "] = { "Direzione: ", "Direção: ", "Kierunek: ", "Yön: ", "Směr: " }
P["Position: "] = { "Posizione: ", "Posição: ", "Pozycja: ", "Konum: ", "Pozice: " }
P["Rotation: "] = { "Rotazione: ", "Rotação: ", "Obrót: ", "Dönüş: ", "Natočení: " }
P["Godmode: "] = { "Invincibilità: ", "Modo deus: ", "Nieśmiertelność: ", "Ölümsüzlük: ", "Nesmrtelnost: " }
P["Damage: "] = { "Danni: ", "Dano: ", "Uszkodzenia: ", "Hasar: ", "Poškození: " }
P["Owner: "] = { "Veicolo: ", "Veículo: ", "Pojazd: ", "Araç: ", "Vozidlo: " }
P["Speed: "] = { "Velocità: ", "Velocidade: ", "Prędkość: ", "Hız: ", "Rychlost: " }
P["Gear: "] = { "Marcia: ", "Marcha: ", "Bieg: ", "Vites: ", "Rychlostní stupeň: " }
P["Fuel: "] = { "Carburante: ", "Combustível: ", "Paliwo: ", "Yakıt: ", "Palivo: " }
P["Rust: "] = { "Ruggine: ", "Ferrugem: ", "Rdza: ", "Pas: ", "Rez: " }
P["Dirt: "] = { "Sporco: ", "Sujeira: ", "Brud: ", "Kir: ", "Špína: " }
P["Color "] = { "Colore ", "Cor ", "Kolor ", "Renk ", "Barva " }

local W = I18n.More.Words
W["true"] = { "sì", "sim", "tak", "evet", "ano" }
W["false"] = { "no", "não", "nie", "hayır", "ne" }
W["None"] = { "nessuna", "nenhuma", "brak", "yok", "žádná" }

-- The five languages become the last columns of the rows of i18n.lua (I18n.S, and
-- I18n.Legacy with the prefixes and the words), named in I18n.Columns and
-- I18n.LegacyColumns.
local sFrom, lFrom = #I18n.Columns, #I18n.LegacyColumns
for j, code in ipairs({ "it", "pt", "pl", "tr", "cs" }) do
	I18n.Columns[sFrom + j] = code
	I18n.LegacyColumns[lFrom + j] = code
end
local function append(base, row, from)
	if base ~= nil and row ~= nil then
		for j = 1, 5 do
			base[from + j] = row[j]
		end
	end
end
for key, row in pairs(S) do
	append(I18n.S[key], row, sFrom)
end
for text, row in pairs(L) do
	append(I18n.Legacy[text], row, lFrom)
end
for _, p in ipairs(I18n.LegacyPrefixes) do
	append(p[2], P[p[1]], lFrom)
end
for word, row in pairs(W) do
	append(I18n.LegacyWords[word], row, lFrom)
end
