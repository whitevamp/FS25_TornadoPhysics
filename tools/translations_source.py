# -*- coding: utf-8 -*-
"""
translations_source.py - every player-visible text of Tornado Physics in all supported languages.

Edit texts HERE, then run   python build_translations.py   to regenerate translations/translation_xx.xml.
Rules (checked by the build script):
  * every key must have a text for every language in LANGUAGES
  * every language must use the same placeholders (%d, %s, %.0f ...) in the same order
  * keys are global in FS25: keep the "tp_" prefix so they cannot clash with other mods
Language codes are the game's own (l10n_xx): en, de, fr, pl, es, it, nl.
"""

LANGUAGES = ["en", "de", "fr", "pl", "es", "it", "nl"]

T = {}


def t(key, en, de, fr, pl, es, it, nl):
    assert key not in T, key
    T[key] = {"en": en, "de": de, "fr": fr, "pl": pl, "es": es, "it": it, "nl": nl}


# =====================================================================================================
# KEY BINDING
# =====================================================================================================
t("input_TORNADO_MENU",
  "Tornado Control Panel", "Tornado-Kontrollzentrum", "Panneau de contrôle Tornade", "Panel sterowania tornada",
  "Panel de control del tornado", "Pannello di controllo tornado", "Tornado-bedieningspaneel")

# =====================================================================================================
# CONTROL PANEL - general
# =====================================================================================================
t("tp_title", "Tornado Physics - Control Panel", "Tornado Physik - Kontrollzentrum", "Physique Tornade - Panneau de contrôle",
  "Fizyka tornada - Panel sterowania", "Física del tornado - Panel de control", "Fisica del tornado - Pannello di controllo",
  "Tornadofysica - Bedieningspaneel")
t("tp_tab_settings", "Settings", "Einstellungen", "Réglages", "Ustawienia", "Ajustes", "Impostazioni", "Instellingen")
t("tp_tab_physics", "Physics", "Physik", "Physique", "Fizyka", "Física", "Fisica", "Fysica")
t("tp_tab_tuning", "Tuning", "Feinabstimmung", "Ajustements", "Strojenie", "Ajuste fino", "Regolazione", "Afstelling")
t("tp_tab_effects", "Effects", "Effekte", "Effets", "Efekty", "Efectos", "Effetti", "Effecten")
t("tp_tab_modules", "Modules", "Module", "Modules", "Moduły", "Módulos", "Moduli", "Modules")
t("tp_tab_developer", "Developer", "Entwickler", "Développeur", "Deweloper", "Desarrollador", "Sviluppatore", "Ontwikkelaar")
t("tp_btn_close", "Close", "Schließen", "Fermer", "Zamknij", "Cerrar", "Chiudi", "Sluiten")
t("tp_btn_save_settings", "Save settings", "Einstellungen speichern", "Enregistrer les réglages", "Zapisz ustawienia",
  "Guardar ajustes", "Salva impostazioni", "Instellingen opslaan")
t("tp_none", "none", "keiner", "aucune", "brak", "ninguno", "nessuno", "geen")
t("tp_na", "n/a", "k. A.", "n/d", "b/d", "n/d", "n/d", "n.v.t.")

# =====================================================================================================
# SETTINGS TAB
# =====================================================================================================
t("tp_sec_configuration", "Configuration", "Konfiguration", "Configuration", "Konfiguracja", "Configuración", "Configurazione", "Configuratie")
t("tp_autosave", "Auto-save on close", "Beim Schließen automatisch speichern", "Enregistrement auto à la fermeture",
  "Autozapis przy zamknięciu", "Guardar al cerrar", "Salvataggio automatico alla chiusura", "Automatisch opslaan bij sluiten")
t("tp_tip_autosave",
  "Write modSettings/TornadoPhysics_Config.xml automatically when this panel is closed and something was changed.",
  "Schreibt modSettings/TornadoPhysics_Config.xml automatisch, wenn dieses Menü geschlossen und etwas geändert wurde.",
  "Écrit automatiquement modSettings/TornadoPhysics_Config.xml à la fermeture de ce panneau si quelque chose a été modifié.",
  "Automatycznie zapisuje modSettings/TornadoPhysics_Config.xml po zamknięciu panelu, jeśli coś zmieniono.",
  "Escribe modSettings/TornadoPhysics_Config.xml automáticamente al cerrar este panel si se ha cambiado algo.",
  "Scrive automaticamente modSettings/TornadoPhysics_Config.xml alla chiusura del pannello se qualcosa è stato modificato.",
  "Schrijft modSettings/TornadoPhysics_Config.xml automatisch weg wanneer dit paneel wordt gesloten en er iets is gewijzigd.")
t("tp_btn_save_now", "Save now", "Jetzt speichern", "Enregistrer", "Zapisz teraz", "Guardar ahora", "Salva ora", "Nu opslaan")
t("tp_save_xml", "Save settings to XML (t_set save)", "Einstellungen in XML speichern (t_set save)",
  "Enregistrer les réglages en XML (t_set save)", "Zapisz ustawienia do XML (t_set save)",
  "Guardar ajustes en XML (t_set save)", "Salva impostazioni in XML (t_set save)", "Instellingen opslaan in XML (t_set save)")
t("tp_sec_factory_reset", "Factory reset", "Werkseinstellungen", "Réinitialisation", "Ustawienia fabryczne",
  "Restablecer valores", "Ripristino", "Fabrieksinstellingen")
t("tp_btn_reset", "Reset", "Zurücksetzen", "Réinitialiser", "Resetuj", "Restablecer", "Ripristina", "Herstellen")
t("tp_btn_reset_all", "Reset all", "Alles zurücksetzen", "Tout réinitialiser", "Resetuj wszystko", "Restablecer todo",
  "Ripristina tutto", "Alles herstellen")
t("tp_reset_physics", "Physics defaults", "Physik-Standardwerte", "Physique par défaut", "Domyślne ustawienia fizyki",
  "Física por defecto", "Fisica predefinita", "Standaard fysica")
t("tp_reset_tuning", "Tuning defaults", "Feinabstimmung-Standardwerte", "Ajustements par défaut", "Domyślne strojenie",
  "Ajuste fino por defecto", "Regolazione predefinita", "Standaard afstelling")
t("tp_reset_cargo", "Cargo defaults", "Ladung-Standardwerte", "Chargement par défaut", "Domyślny ładunek",
  "Carga por defecto", "Carico predefinito", "Standaard lading")
t("tp_reset_husbandry", "Husbandry defaults", "Tierhaltung-Standardwerte", "Élevage par défaut", "Domyślna hodowla",
  "Ganadería por defecto", "Allevamento predefinito", "Standaard veeteelt")
t("tp_reset_traffic", "Traffic defaults", "Verkehr-Standardwerte", "Circulation par défaut", "Domyślny ruch",
  "Tráfico por defecto", "Traffico predefinito", "Standaard verkeer")
t("tp_reset_climate", "Climate defaults", "Klima-Standardwerte", "Climat par défaut", "Domyślny klimat",
  "Clima por defecto", "Clima predefinito", "Standaard klimaat")
t("tp_reset_everything", "Everything", "Alles", "Tout", "Wszystko", "Todo", "Tutto", "Alles")
t("tp_sec_info", "Info", "Info", "Info", "Informacje", "Información", "Info", "Info")
t("tp_info_instant", "Changes apply instantly, exactly like the t_ console commands.",
  "Änderungen gelten sofort, genau wie die t_-Konsolenbefehle.",
  "Les modifications s'appliquent immédiatement, comme les commandes de console t_.",
  "Zmiany działają natychmiast, tak jak polecenia konsoli t_.",
  "Los cambios se aplican al instante, igual que los comandos de consola t_.",
  "Le modifiche si applicano subito, esattamente come i comandi console t_.",
  "Wijzigingen gelden direct, net als de t_-consoleopdrachten.")
t("tp_note_key", "Open this panel any time with the Tornado Control Panel key (rebind under Controls).",
  "Öffne dieses Menü jederzeit mit der Taste für das Tornado-Kontrollzentrum (änderbar unter Steuerung).",
  "Ouvrez ce panneau à tout moment avec la touche du panneau de contrôle Tornade (modifiable dans Commandes).",
  "Otwórz ten panel w każdej chwili klawiszem panelu sterowania tornada (zmiana w Sterowaniu).",
  "Abre este panel en cualquier momento con la tecla del panel de control del tornado (se cambia en Controles).",
  "Apri questo pannello in qualsiasi momento con il tasto del pannello tornado (modificabile in Comandi).",
  "Open dit paneel altijd met de toets van het tornado-bedieningspaneel (aan te passen bij Besturing).")
t("tp_note_mp_admin", "Multiplayer (admin): gameplay changes are sent to the server and apply to every player.",
  "Mehrspieler (Admin): Spieländerungen werden an den Server gesendet und gelten für alle Spieler.",
  "Multijoueur (admin) : les modifications de jeu sont envoyées au serveur et s'appliquent à tous les joueurs.",
  "Gra wieloosobowa (admin): zmiany rozgrywki trafiają na serwer i dotyczą wszystkich graczy.",
  "Multijugador (admin): los cambios de juego se envían al servidor y se aplican a todos los jugadores.",
  "Multigiocatore (admin): le modifiche di gioco vengono inviate al server e valgono per tutti i giocatori.",
  "Multiplayer (beheerder): spelwijzigingen gaan naar de server en gelden voor alle spelers.")
t("tp_note_mp_client",
  "Multiplayer: showing the server's settings. Only the host or a server admin can change gameplay; sound, ring, map overlay and debug are yours.",
  "Mehrspieler: Es werden die Einstellungen des Servers angezeigt. Nur der Host oder ein Admin kann das Spielgeschehen ändern; Ton, Ring, Karten-Overlay und Debug gehören dir.",
  "Multijoueur : réglages du serveur affichés. Seul l'hôte ou un admin peut modifier le jeu ; son, anneau, superposition de carte et débogage sont à vous.",
  "Gra wieloosobowa: pokazane są ustawienia serwera. Rozgrywkę może zmienić tylko gospodarz lub admin; dźwięk, pierścień, nakładka mapy i debug należą do Ciebie.",
  "Multijugador: se muestran los ajustes del servidor. Solo el anfitrión o un admin puede cambiar el juego; sonido, anillo, capa del mapa y depuración son tuyos.",
  "Multigiocatore: sono mostrate le impostazioni del server. Solo l'host o un admin può modificare il gioco; suono, anello, overlay mappa e debug sono tuoi.",
  "Multiplayer: de instellingen van de server worden getoond. Alleen de host of een beheerder kan het spel wijzigen; geluid, ring, kaartoverlay en debug zijn van jou.")
t("tp_confirm_reset_physics", "Reset the physics settings to factory defaults? This is saved immediately.",
  "Physik-Einstellungen auf Werkseinstellungen zurücksetzen? Dies wird sofort gespeichert.",
  "Réinitialiser les réglages de physique ? Cela est enregistré immédiatement.",
  "Przywrócić fabryczne ustawienia fizyki? Zostanie to od razu zapisane.",
  "¿Restablecer los ajustes de física? Se guarda al instante.",
  "Ripristinare le impostazioni della fisica? Viene salvato subito.",
  "Fysica-instellingen terugzetten naar de fabrieksinstellingen? Dit wordt direct opgeslagen.")
t("tp_confirm_reset_tuning", "Reset the tuning values to factory defaults? This is saved immediately.",
  "Feinabstimmung auf Werkseinstellungen zurücksetzen? Dies wird sofort gespeichert.",
  "Réinitialiser les valeurs d'ajustement ? Cela est enregistré immédiatement.",
  "Przywrócić fabryczne wartości strojenia? Zostanie to od razu zapisane.",
  "¿Restablecer los valores de ajuste fino? Se guarda al instante.",
  "Ripristinare i valori di regolazione? Viene salvato subito.",
  "Afstelwaarden terugzetten naar de fabrieksinstellingen? Dit wordt direct opgeslagen.")
t("tp_confirm_reset_cargo", "Reset the cargo settings to factory defaults? This is saved immediately.",
  "Ladungs-Einstellungen auf Werkseinstellungen zurücksetzen? Dies wird sofort gespeichert.",
  "Réinitialiser les réglages de chargement ? Cela est enregistré immédiatement.",
  "Przywrócić fabryczne ustawienia ładunku? Zostanie to od razu zapisane.",
  "¿Restablecer los ajustes de carga? Se guarda al instante.",
  "Ripristinare le impostazioni del carico? Viene salvato subito.",
  "Lading-instellingen terugzetten naar de fabrieksinstellingen? Dit wordt direct opgeslagen.")
t("tp_confirm_reset_husbandry", "Reset the husbandry settings to factory defaults? This is saved immediately.",
  "Tierhaltungs-Einstellungen auf Werkseinstellungen zurücksetzen? Dies wird sofort gespeichert.",
  "Réinitialiser les réglages d'élevage ? Cela est enregistré immédiatement.",
  "Przywrócić fabryczne ustawienia hodowli? Zostanie to od razu zapisane.",
  "¿Restablecer los ajustes de ganadería? Se guarda al instante.",
  "Ripristinare le impostazioni dell'allevamento? Viene salvato subito.",
  "Veeteelt-instellingen terugzetten naar de fabrieksinstellingen? Dit wordt direct opgeslagen.")
t("tp_confirm_reset_traffic", "Reset the traffic roadblock settings to factory defaults? This is saved immediately.",
  "Einstellungen der Straßensperren auf Werkseinstellungen zurücksetzen? Dies wird sofort gespeichert.",
  "Réinitialiser les réglages des barrages routiers ? Cela est enregistré immédiatement.",
  "Przywrócić fabryczne ustawienia blokad drogowych? Zostanie to od razu zapisane.",
  "¿Restablecer los ajustes de los controles de tráfico? Se guarda al instante.",
  "Ripristinare le impostazioni dei blocchi stradali? Viene salvato subito.",
  "Wegversperring-instellingen terugzetten naar de fabrieksinstellingen? Dit wordt direct opgeslagen.")
t("tp_confirm_reset_climate", "Reset the real-life climate settings to factory defaults? This is saved immediately.",
  "Einstellungen des realen Klimas auf Werkseinstellungen zurücksetzen? Dies wird sofort gespeichert.",
  "Réinitialiser les réglages du climat réel ? Cela est enregistré immédiatement.",
  "Przywrócić fabryczne ustawienia prawdziwego klimatu? Zostanie to od razu zapisane.",
  "¿Restablecer los ajustes del clima real? Se guarda al instante.",
  "Ripristinare le impostazioni del clima reale? Viene salvato subito.",
  "Instellingen van het echte klimaat terugzetten naar de fabrieksinstellingen? Dit wordt direct opgeslagen.")
t("tp_confirm_reset_all", "Reset ALL settings to factory defaults? This is saved immediately.",
  "ALLE Einstellungen auf Werkseinstellungen zurücksetzen? Dies wird sofort gespeichert.",
  "Réinitialiser TOUS les réglages ? Cela est enregistré immédiatement.",
  "Przywrócić WSZYSTKIE ustawienia fabryczne? Zostanie to od razu zapisane.",
  "¿Restablecer TODOS los ajustes? Se guarda al instante.",
  "Ripristinare TUTTE le impostazioni? Viene salvato subito.",
  "ALLE instellingen terugzetten naar de fabrieksinstellingen? Dit wordt direct opgeslagen.")

# =====================================================================================================
# PHYSICS TAB - real-life climate
# =====================================================================================================
t("tp_sec_climate", "Real-life climate", "Reales Klima", "Climat réel", "Prawdziwy klimat", "Clima real", "Clima reale", "Echt klimaat")
t("tp_climate", "Real-life tornado climate", "Reales Tornado-Klima", "Climat réel des tornades", "Prawdziwy klimat tornad",
  "Clima real de tornados", "Clima reale dei tornado", "Echt tornadoklimaat")
t("tp_tip_climate",
  "On: each tornado's EF rating, size, hail and wind follow real recorded statistics for the region (mostly EF0-EF1, EF4-EF5 rare). Off: classic mode, every size equally likely and random storm weather.",
  "An: EF-Stufe, Größe, Hagel und Wind jedes Tornados folgen echten Statistiken der Region (meist EF0-EF1, EF4-EF5 selten). Aus: klassischer Modus, jede Größe gleich wahrscheinlich und zufälliges Unwetter.",
  "Activé : catégorie EF, taille, grêle et vent de chaque tornade suivent les vraies statistiques de la région (surtout EF0-EF1, EF4-EF5 rares). Désactivé : mode classique, toutes les tailles sont équiprobables et l'orage est aléatoire.",
  "Wł.: kategoria EF, rozmiar, grad i wiatr każdego tornada są zgodne z prawdziwymi statystykami regionu (głównie EF0-EF1, EF4-EF5 rzadko). Wył.: tryb klasyczny, każdy rozmiar równie prawdopodobny i losowa burza.",
  "Activado: la categoría EF, el tamaño, el granizo y el viento de cada tornado siguen las estadísticas reales de la región (sobre todo EF0-EF1, EF4-EF5 raros). Desactivado: modo clásico, todos los tamaños igual de probables y tormenta aleatoria.",
  "Attivo: categoria EF, dimensione, grandine e vento di ogni tornado seguono le statistiche reali della regione (soprattutto EF0-EF1, EF4-EF5 rari). Disattivo: modalità classica, ogni dimensione è ugualmente probabile e il temporale è casuale.",
  "Aan: EF-categorie, grootte, hagel en wind van elke tornado volgen de echte statistieken van de regio (meestal EF0-EF1, EF4-EF5 zeldzaam). Uit: klassieke modus, elke grootte even waarschijnlijk en willekeurig onweer.")
t("tp_climate_region", "Climate region", "Klimaregion", "Région climatique", "Region klimatyczny", "Región climática",
  "Regione climatica", "Klimaatregio")
t("tp_tip_climate_region",
  "Which region's tornado statistics to use. Auto: the base US map uses US-wide data, a mod map whose name contains a state, province or country uses that region, other maps keep the classic roll.",
  "Welche Tornadostatistik verwendet wird. Auto: Die US-Grundkarte nutzt die Daten der ganzen USA, eine Modkarte mit einem Bundesstaat, einer Provinz oder einem Land im Namen nutzt diese Region, andere Karten behalten den klassischen Wurf.",
  "Statistiques de tornades à utiliser. Auto : la carte US de base utilise les données de tous les États-Unis, une carte moddée dont le nom contient un État, une province ou un pays utilise cette région, les autres cartes gardent le tirage classique.",
  "Statystyki tornad których regionu użyć. Auto: podstawowa mapa USA używa danych całych USA, mapa z modów ze stanem, prowincją lub krajem w nazwie używa tego regionu, inne mapy zostają przy klasycznym losowaniu.",
  "Qué estadísticas de tornados usar. Auto: el mapa base de EE. UU. usa los datos de todo el país, un mapa mod con un estado, provincia o país en su nombre usa esa región, los demás mapas mantienen la tirada clásica.",
  "Quali statistiche dei tornado usare. Auto: la mappa base USA usa i dati di tutti gli USA, una mappa mod con uno stato, una provincia o un paese nel nome usa quella regione, le altre mappe mantengono il tiro classico.",
  "Welke tornadostatistieken worden gebruikt. Auto: de standaard VS-kaart gebruikt gegevens van de hele VS, een modkaart met een staat, provincie of land in de naam gebruikt die regio, andere kaarten houden de klassieke worp.")
t("tp_seasons", "Real seasons and time of day", "Echte Jahres- und Tageszeiten", "Saisons et heures réelles",
  "Prawdziwe pory roku i dnia", "Estaciones y horas reales", "Stagioni e orari reali", "Echte seizoenen en tijdstippen")
t("tp_tip_seasons",
  "Tornadoes come in the region's real tornado months and mostly in the late afternoon. The map's overall tornado rate is kept (see Tornado frequency).",
  "Tornados kommen in den echten Tornadomonaten der Region und meist am späten Nachmittag. Die Gesamthäufigkeit der Karte bleibt erhalten (siehe Tornado-Häufigkeit).",
  "Les tornades arrivent pendant les vrais mois à tornades de la région, surtout en fin d'après-midi. La fréquence globale de la carte est conservée (voir Fréquence des tornades).",
  "Tornada pojawiają się w prawdziwych miesiącach tornad danego regionu, głównie późnym popołudniem. Ogólna częstotliwość mapy zostaje zachowana (patrz Częstotliwość tornad).",
  "Los tornados llegan en los meses reales de tornados de la región y sobre todo a última hora de la tarde. Se mantiene la frecuencia general del mapa (ver Frecuencia de tornados).",
  "I tornado arrivano nei veri mesi dei tornado della regione e soprattutto nel tardo pomeriggio. La frequenza complessiva della mappa resta invariata (vedi Frequenza dei tornado).",
  "Tornado's komen in de echte tornadomaanden van de regio en meestal laat in de middag. De totale tornadofrequentie van de kaart blijft gelijk (zie Tornadofrequentie).")
t("tp_direction", "Real track direction", "Echte Zugrichtung", "Direction réelle", "Prawdziwy kierunek", "Dirección real",
  "Direzione reale", "Echte trekrichting")
t("tp_tip_direction",
  "Natural tornadoes travel the way they do in the region (in the US mostly toward the north-east). The console spawn still aims where you look.",
  "Natürliche Tornados ziehen so wie in der Region (in den USA meist nach Nordosten). Ein über die Konsole erzeugter Tornado zieht weiterhin in Blickrichtung.",
  "Les tornades naturelles se déplacent comme dans la région (aux États-Unis surtout vers le nord-est). Une tornade créée par la console part toujours dans la direction du regard.",
  "Naturalne tornada poruszają się jak w danym regionie (w USA głównie na północny wschód). Tornado z konsoli nadal leci tam, gdzie patrzysz.",
  "Los tornados naturales se desplazan como en la región (en EE. UU. sobre todo hacia el noreste). Un tornado creado por consola sigue yendo hacia donde miras.",
  "I tornado naturali si muovono come nella regione (negli USA soprattutto verso nord-est). Un tornado creato da console va ancora nella direzione in cui guardi.",
  "Natuurlijke tornado's trekken zoals in de regio (in de VS meestal naar het noordoosten). Een tornado via de console gaat nog steeds de kijkrichting op.")
t("tp_outbreaks", "Outbreak days", "Ausbruchstage", "Épisodes de tornades", "Dni wybuchów tornad", "Días de brotes",
  "Giorni di focolai", "Uitbraakdagen")
t("tp_tip_outbreaks",
  "With the region's real odds, a touchdown can start a busy storm day: more tornadoes follow 30-120 in-game minutes apart, until the limit below or 22:00.",
  "Mit den echten Wahrscheinlichkeiten der Region kann ein Tornado einen Unwettertag auslösen: Weitere Tornados folgen im Abstand von 30-120 Spielminuten, bis zum Limit unten oder bis 22:00.",
  "Selon les vraies probabilités de la région, une tornade peut lancer une journée orageuse : d'autres tornades suivent à 30-120 minutes de jeu d'intervalle, jusqu'à la limite ci-dessous ou 22:00.",
  "Z prawdziwym prawdopodobieństwem regionu tornado może rozpocząć burzowy dzień: kolejne tornada pojawiają się co 30-120 minut gry, do limitu poniżej lub do 22:00.",
  "Con las probabilidades reales de la región, un tornado puede iniciar un día de tormentas: siguen más tornados cada 30-120 minutos de juego, hasta el límite de abajo o las 22:00.",
  "Con le probabilità reali della regione, un tornado può dare inizio a una giornata di temporali: altri tornado seguono a 30-120 minuti di gioco l'uno dall'altro, fino al limite sotto o alle 22:00.",
  "Met de echte kansen van de regio kan een tornado een onweersdag starten: er volgen meer tornado's met 30-120 spelminuten ertussen, tot de limiet hieronder of tot 22:00.")
t("tp_frequency", "Tornado frequency", "Tornado-Häufigkeit", "Fréquence des tornades", "Częstotliwość tornad",
  "Frecuencia de tornados", "Frequenza dei tornado", "Tornadofrequentie")
t("tp_tip_frequency", "Multiplier on how often the map produces tornadoes in real-life mode. 1x = the map's own rate.",
  "Multiplikator dafür, wie oft die Karte im realen Modus Tornados erzeugt. 1x = eigene Rate der Karte.",
  "Multiplicateur de la fréquence des tornades de la carte en mode réel. 1x = fréquence propre de la carte.",
  "Mnożnik częstotliwości tornad na mapie w trybie rzeczywistym. 1x = własna częstotliwość mapy.",
  "Multiplicador de la frecuencia de tornados del mapa en modo real. 1x = frecuencia propia del mapa.",
  "Moltiplicatore della frequenza dei tornado della mappa in modalità reale. 1x = frequenza propria della mappa.",
  "Vermenigvuldiger voor hoe vaak de kaart tornado's maakt in de echte modus. 1x = eigen frequentie van de kaart.")
t("tp_outbreak_max", "Max tornadoes per outbreak", "Max. Tornados pro Ausbruch", "Tornades max. par épisode",
  "Maks. tornad na wybuch", "Máx. tornados por brote", "Max tornado per focolaio", "Max. tornado's per uitbraak")
t("tp_tip_outbreak_max", "Most tornadoes one outbreak day can bring, the first one included.",
  "Höchstzahl an Tornados an einem Ausbruchstag, einschließlich des ersten.",
  "Nombre maximal de tornades sur une journée d'épisode, la première comprise.",
  "Największa liczba tornad w dniu wybuchu, łącznie z pierwszym.",
  "Máximo de tornados en un día de brote, incluido el primero.",
  "Numero massimo di tornado in un giorno di focolaio, il primo compreso.",
  "Maximaal aantal tornado's op een uitbraakdag, de eerste meegerekend.")
t("tp_note_climate_missing", "Climate data (DB/TornadoClimate*.xml) not found - classic mode only.",
  "Klimadaten (DB/TornadoClimate*.xml) nicht gefunden - nur klassischer Modus.",
  "Données climatiques (DB/TornadoClimate*.xml) introuvables - mode classique uniquement.",
  "Nie znaleziono danych klimatycznych (DB/TornadoClimate*.xml) - tylko tryb klasyczny.",
  "No se encontraron datos climáticos (DB/TornadoClimate*.xml): solo modo clásico.",
  "Dati climatici (DB/TornadoClimate*.xml) non trovati - solo modalità classica.",
  "Klimaatgegevens (DB/TornadoClimate*.xml) niet gevonden - alleen klassieke modus.")
t("tp_note_classic", "Classic mode: every tornado size is equally likely.",
  "Klassischer Modus: Jede Tornadogröße ist gleich wahrscheinlich.",
  "Mode classique : toutes les tailles de tornade sont équiprobables.",
  "Tryb klasyczny: każdy rozmiar tornada jest równie prawdopodobny.",
  "Modo clásico: todos los tamaños de tornado son igual de probables.",
  "Modalità classica: ogni dimensione di tornado è ugualmente probabile.",
  "Klassieke modus: elke tornadogrootte is even waarschijnlijk.")
t("tp_note_no_region", "No climate data for this map's region yet - pick a region above, classic roll used until then.",
  "Noch keine Klimadaten für die Region dieser Karte - wähle oben eine Region, bis dahin gilt der klassische Wurf.",
  "Pas encore de données climatiques pour la région de cette carte - choisissez une région ci-dessus, tirage classique en attendant.",
  "Brak danych klimatycznych dla regionu tej mapy - wybierz region powyżej, do tego czasu klasyczne losowanie.",
  "Aún no hay datos climáticos para la región de este mapa: elige una región arriba, mientras tanto se usa la tirada clásica.",
  "Ancora nessun dato climatico per la regione di questa mappa - scegli una regione sopra, fino ad allora tiro classico.",
  "Nog geen klimaatgegevens voor de regio van deze kaart - kies hierboven een regio, tot dan de klassieke worp.")
t("tp_note_next_region", "Next tornado uses %s statistics.", "Der nächste Tornado nutzt die Statistik von %s.",
  "La prochaine tornade utilise les statistiques de %s.", "Następne tornado używa statystyk: %s.",
  "El próximo tornado usa las estadísticas de %s.", "Il prossimo tornado usa le statistiche di %s.",
  "De volgende tornado gebruikt de statistieken van %s.")
t("tp_note_last_roll", "Last roll: %s EF-%d", "Letzter Wurf: %s EF-%d", "Dernier tirage : %s EF-%d",
  "Ostatnie losowanie: %s EF-%d", "Última tirada: %s EF-%d", "Ultimo tiro: %s EF-%d", "Laatste worp: %s EF-%d")
t("tp_note_real_width", "(real-world width %.0f m)", "(echte Breite %.0f m)", "(largeur réelle %.0f m)",
  "(prawdziwa szerokość %.0f m)", "(anchura real %.0f m)", "(larghezza reale %.0f m)", "(echte breedte %.0f m)")
t("tp_note_storm", "Storm: hail %s, gusts %.0f km/h.", "Unwetter: Hagel %s, Böen %.0f km/h.",
  "Orage : grêle %s, rafales %.0f km/h.", "Burza: grad %s, porywy %.0f km/h.",
  "Tormenta: granizo %s, rachas %.0f km/h.", "Temporale: grandine %s, raffiche %.0f km/h.",
  "Onweer: hagel %s, windstoten %.0f km/h.")
t("tp_auto", "Auto (%s)", "Auto (%s)", "Auto (%s)", "Auto (%s)", "Auto (%s)", "Auto (%s)", "Auto (%s)")
t("tp_auto_none", "no data, classic", "keine Daten, klassisch", "pas de données, classique", "brak danych, klasyczny",
  "sin datos, clásico", "nessun dato, classico", "geen gegevens, klassiek")

# =====================================================================================================
# PHYSICS TAB - storm / damage / objects / border
# =====================================================================================================
t("tp_sec_storm", "Storm", "Sturm", "Tempête", "Burza", "Tormenta", "Tempesta", "Storm")
t("tp_radius", "Base radius", "Grundradius", "Rayon de base", "Promień bazowy", "Radio base", "Raggio base", "Basisstraal")
t("tp_tip_radius", "Base radius of the tornado. Changing it re-rolls the tornado size / EF rating.",
  "Grundradius des Tornados. Eine Änderung würfelt Größe / EF-Stufe neu.",
  "Rayon de base de la tornade. Le modifier relance la taille / catégorie EF.",
  "Promień bazowy tornada. Zmiana losuje ponownie rozmiar / kategorię EF.",
  "Radio base del tornado. Cambiarlo vuelve a sortear el tamaño / la categoría EF.",
  "Raggio base del tornado. Cambiarlo ritira dimensione / categoria EF.",
  "Basisstraal van de tornado. Wijzigen gooit grootte / EF-categorie opnieuw.")
t("tp_power", "Ejection power", "Auswurfkraft", "Force d'éjection", "Siła wyrzutu", "Fuerza de expulsión",
  "Forza di espulsione", "Uitwerpkracht")
t("tp_tip_power", "Force used to throw objects out of the funnel.", "Kraft, mit der Objekte aus dem Trichter geschleudert werden.",
  "Force qui projette les objets hors de l'entonnoir.", "Siła wyrzucająca obiekty z leja.",
  "Fuerza con la que se lanzan los objetos fuera del embudo.", "Forza con cui gli oggetti vengono lanciati fuori dall'imbuto.",
  "Kracht waarmee objecten uit de trechter worden geslingerd.")
t("tp_heavy", "Heavy mass threshold", "Schwellenwert schwere Masse", "Seuil de masse lourde", "Próg ciężkiej masy",
  "Umbral de masa pesada", "Soglia massa pesante", "Drempel zware massa")
t("tp_tip_heavy", "Mass (tons) above which a vehicle is treated as heavy.", "Masse (Tonnen), ab der ein Fahrzeug als schwer gilt.",
  "Masse (tonnes) au-delà de laquelle un véhicule est considéré comme lourd.", "Masa (tony), powyżej której pojazd uznaje się za ciężki.",
  "Masa (toneladas) a partir de la cual un vehículo se considera pesado.", "Massa (tonnellate) oltre la quale un veicolo è considerato pesante.",
  "Massa (ton) vanaf waar een voertuig als zwaar geldt.")
t("tp_btn_randomize", "Randomize", "Neu würfeln", "Aléatoire", "Losuj", "Aleatorio", "Casuale", "Willekeurig")
t("tp_randomize", "Force new size / EF rating", "Neue Größe / EF-Stufe erzwingen", "Forcer nouvelle taille / catégorie EF",
  "Wymuś nowy rozmiar / kategorię EF", "Forzar nuevo tamaño / categoría EF", "Forza nuova dimensione / categoria EF",
  "Nieuwe grootte / EF-categorie forceren")
t("tp_sec_damage", "Damage", "Schaden", "Dégâts", "Uszkodzenia", "Daños", "Danni", "Schade")
t("tp_dmg_in", "Core damage rate", "Schadensrate im Kern", "Dégâts au cœur", "Obrażenia w rdzeniu", "Daño en el núcleo",
  "Danno nel nucleo", "Schade in de kern")
t("tp_tip_dmg_in", "Damage per second applied inside the core.", "Schaden pro Sekunde im Kern.",
  "Dégâts par seconde à l'intérieur du cœur.", "Obrażenia na sekundę wewnątrz rdzenia.", "Daño por segundo dentro del núcleo.",
  "Danno al secondo all'interno del nucleo.", "Schade per seconde in de kern.")
t("tp_dmg_out", "Outer damage rate", "Schadensrate außen", "Dégâts extérieurs", "Obrażenia na zewnątrz", "Daño exterior",
  "Danno esterno", "Schade buitenkant")
t("tp_tip_dmg_out", "Damage per second applied in the outer winds.", "Schaden pro Sekunde in den äußeren Winden.",
  "Dégâts par seconde dans les vents extérieurs.", "Obrażenia na sekundę w zewnętrznych wiatrach.",
  "Daño por segundo en los vientos exteriores.", "Danno al secondo nei venti esterni.", "Schade per seconde in de buitenste winden.")
t("tp_outdoor", "Outdoor damage", "Schaden im Freien", "Dégâts en extérieur", "Uszkodzenia na zewnątrz", "Daños al aire libre",
  "Danni all'aperto", "Schade buiten")
t("tp_tip_outdoor", "Damage vehicles that are standing outside.", "Beschädigt Fahrzeuge, die im Freien stehen.",
  "Endommage les véhicules garés en extérieur.", "Uszkadza pojazdy stojące na zewnątrz.", "Daña los vehículos que están al aire libre.",
  "Danneggia i veicoli all'aperto.", "Beschadigt voertuigen die buiten staan.")
t("tp_indoor", "Indoor damage", "Schaden in Gebäuden", "Dégâts en intérieur", "Uszkodzenia w budynkach", "Daños bajo techo",
  "Danni al coperto", "Schade binnen")
t("tp_tip_indoor", "Damage vehicles parked inside sheds as well.", "Beschädigt auch Fahrzeuge in Hallen.",
  "Endommage aussi les véhicules garés dans les hangars.", "Uszkadza też pojazdy stojące w wiatach.",
  "Daña también los vehículos aparcados en naves.", "Danneggia anche i veicoli parcheggiati nei capannoni.",
  "Beschadigt ook voertuigen in schuren.")
t("tp_sec_objects", "Objects", "Objekte", "Objets", "Obiekty", "Objetos", "Oggetti", "Objecten")
t("tp_lift_bales", "Lift bales", "Ballen anheben", "Soulever les balles", "Podnoś bele", "Levantar pacas", "Solleva balle", "Balen optillen")
t("tp_tip_lift_bales", "Let the tornado pick up bales and pallets.", "Der Tornado hebt Ballen und Paletten an.",
  "La tornade soulève les balles et les palettes.", "Tornado podnosi bele i palety.", "El tornado levanta pacas y palés.",
  "Il tornado solleva balle e pallet.", "De tornado tilt balen en pallets op.")
t("tp_lift_logs", "Lift logs", "Baumstämme anheben", "Soulever les troncs", "Podnoś kłody", "Levantar troncos",
  "Solleva tronchi", "Boomstammen optillen")
t("tp_tip_lift_logs", "Let the tornado pick up logs.", "Der Tornado hebt Baumstämme an.", "La tornade soulève les troncs.",
  "Tornado podnosi kłody.", "El tornado levanta troncos.", "Il tornado solleva i tronchi.", "De tornado tilt boomstammen op.")
t("tp_sec_border", "Map border", "Kartenrand", "Bord de carte", "Krawędź mapy", "Borde del mapa", "Bordo mappa", "Kaartrand")
t("tp_border", "Border safety", "Randschutz", "Sécurité du bord", "Ochrona krawędzi", "Protección del borde", "Protezione bordo",
  "Randbeveiliging")
t("tp_tip_border", "Stop physics near the map edge so nothing is thrown off the map.",
  "Stoppt die Physik am Kartenrand, damit nichts von der Karte geschleudert wird.",
  "Arrête la physique près du bord pour que rien ne soit projeté hors de la carte.",
  "Wyłącza fizykę przy krawędzi mapy, aby nic nie wyleciało poza mapę.",
  "Detiene la física cerca del borde para que nada salga despedido del mapa.",
  "Ferma la fisica vicino al bordo perché nulla venga lanciato fuori dalla mappa.",
  "Stopt de fysica bij de kaartrand zodat niets van de kaart wordt geslingerd.")
t("tp_fence", "Geo-fence buffer", "Geo-Zaun-Abstand", "Marge de géo-clôture", "Bufor geo-ogrodzenia", "Margen de geovalla",
  "Margine geo-recinto", "Geo-hekbuffer")
t("tp_tip_fence", "Safety distance from the map border where physics stop.", "Sicherheitsabstand zum Kartenrand, ab dem die Physik stoppt.",
  "Distance de sécurité au bord de la carte où la physique s'arrête.", "Odległość od krawędzi mapy, przy której fizyka się zatrzymuje.",
  "Distancia de seguridad al borde del mapa donde se detiene la física.", "Distanza di sicurezza dal bordo della mappa dove la fisica si ferma.",
  "Veiligheidsafstand tot de kaartrand waar de fysica stopt.")

# =====================================================================================================
# TUNING TAB
# =====================================================================================================
t("tp_sec_movement", "Movement", "Bewegung", "Mouvement", "Ruch", "Movimiento", "Movimento", "Beweging")
t("tp_suction", "Suction speed", "Sauggeschwindigkeit", "Vitesse d'aspiration", "Prędkość zasysania", "Velocidad de succión",
  "Velocità di aspirazione", "Zuigsnelheid")
t("tp_tip_suction", "Inward pull speed.", "Geschwindigkeit des Sogs nach innen.", "Vitesse d'attraction vers le centre.",
  "Prędkość wciągania do środka.", "Velocidad de atracción hacia el centro.", "Velocità di attrazione verso il centro.",
  "Snelheid van de zuiging naar binnen.")
t("tp_lift", "Lift speed", "Hubgeschwindigkeit", "Vitesse d'élévation", "Prędkość unoszenia", "Velocidad de elevación",
  "Velocità di sollevamento", "Hefsnelheid")
t("tp_tip_lift", "Vertical lift speed.", "Vertikale Hubgeschwindigkeit.", "Vitesse d'élévation verticale.",
  "Pionowa prędkość unoszenia.", "Velocidad de elevación vertical.", "Velocità di sollevamento verticale.", "Verticale hefsnelheid.")
t("tp_chaos", "Chaos factor", "Chaosfaktor", "Facteur de chaos", "Współczynnik chaosu", "Factor de caos", "Fattore caos", "Chaosfactor")
t("tp_tip_chaos", "Randomness factor for movement. Higher is more violent.", "Zufallsfaktor der Bewegung. Höher ist heftiger.",
  "Facteur aléatoire du mouvement. Plus élevé = plus violent.", "Losowość ruchu. Wyższa wartość to gwałtowniejsze tornado.",
  "Factor aleatorio del movimiento. Más alto es más violento.", "Fattore di casualità del movimento. Più alto è più violento.",
  "Willekeurigheid van de beweging. Hoger is heftiger.")
t("tp_hover", "Hover height", "Schwebehöhe", "Hauteur de flottement", "Wysokość unoszenia", "Altura de flotación",
  "Altezza di galleggiamento", "Zweefhoogte")
t("tp_tip_hover", "Maximum height for floating objects.", "Maximale Höhe schwebender Objekte.", "Hauteur maximale des objets en suspension.",
  "Maksymalna wysokość unoszących się obiektów.", "Altura máxima de los objetos en el aire.", "Altezza massima degli oggetti sollevati.",
  "Maximale hoogte van zwevende objecten.")
t("tp_max_speed", "Max safe speed", "Max. sichere Geschwindigkeit", "Vitesse max. sûre", "Maks. bezpieczna prędkość",
  "Velocidad máx. segura", "Velocità max sicura", "Max. veilige snelheid")
t("tp_tip_max_speed", "Physics speed cap for lifted objects.", "Geschwindigkeitsgrenze für angehobene Objekte.",
  "Limite de vitesse des objets soulevés.", "Limit prędkości podniesionych obiektów.", "Límite de velocidad de los objetos levantados.",
  "Limite di velocità degli oggetti sollevati.", "Snelheidslimiet voor opgetilde objecten.")
t("tp_destruct_ratio", "Core destruction ratio", "Anteil Zerstörungskern", "Ratio du cœur destructeur", "Udział rdzenia niszczącego",
  "Proporción del núcleo destructivo", "Quota del nucleo distruttivo", "Aandeel vernietigende kern")
t("tp_tip_destruct_ratio", "Share of the radius that counts as the destructive core.", "Anteil des Radius, der als zerstörerischer Kern gilt.",
  "Part du rayon considérée comme cœur destructeur.", "Część promienia uznawana za niszczący rdzeń.",
  "Parte del radio que cuenta como núcleo destructivo.", "Parte del raggio considerata nucleo distruttivo.",
  "Deel van de straal dat als vernietigende kern telt.")
t("tp_sec_bales", "Bales", "Ballen", "Balles", "Bele", "Pacas", "Balle", "Balen")
t("tp_bale_orbit", "Bale orbit speed", "Ballen-Kreisgeschwindigkeit", "Vitesse de rotation des balles", "Prędkość krążenia bel",
  "Velocidad de órbita de pacas", "Velocità di rotazione balle", "Draaisnelheid balen")
t("tp_tip_bale_orbit", "Orbit speed for bales.", "Kreisgeschwindigkeit der Ballen.", "Vitesse de rotation des balles.",
  "Prędkość krążenia bel.", "Velocidad de órbita de las pacas.", "Velocità di rotazione delle balle.", "Draaisnelheid van balen.")
t("tp_bale_suction", "Bale suction speed", "Ballen-Sauggeschwindigkeit", "Vitesse d'aspiration des balles", "Prędkość zasysania bel",
  "Velocidad de succión de pacas", "Velocità di aspirazione balle", "Zuigsnelheid balen")
t("tp_tip_bale_suction", "Suction speed for bales.", "Sauggeschwindigkeit der Ballen.", "Vitesse d'aspiration des balles.",
  "Prędkość zasysania bel.", "Velocidad de succión de las pacas.", "Velocità di aspirazione delle balle.", "Zuigsnelheid van balen.")
t("tp_sec_ejection", "Ejection cycle", "Auswurfzyklus", "Cycle d'éjection", "Cykl wyrzutu", "Ciclo de expulsión",
  "Ciclo di espulsione", "Uitwerpcyclus")
t("tp_purge_time", "Ejection duration", "Auswurfdauer", "Durée d'éjection", "Czas wyrzutu", "Duración de expulsión",
  "Durata espulsione", "Uitwerpduur")
t("tp_tip_purge_time", "How long each ejection phase lasts.", "Wie lange jede Auswurfphase dauert.", "Durée de chaque phase d'éjection.",
  "Jak długo trwa każda faza wyrzutu.", "Cuánto dura cada fase de expulsión.", "Quanto dura ogni fase di espulsione.",
  "Hoe lang elke uitwerpfase duurt.")
t("tp_purge_int", "Ejection interval", "Auswurfintervall", "Intervalle d'éjection", "Odstęp wyrzutu", "Intervalo de expulsión",
  "Intervallo espulsione", "Uitwerpinterval")
t("tp_tip_purge_int", "Time between ejection phases.", "Zeit zwischen den Auswurfphasen.", "Temps entre les phases d'éjection.",
  "Czas między fazami wyrzutu.", "Tiempo entre fases de expulsión.", "Tempo tra le fasi di espulsione.", "Tijd tussen uitwerpfasen.")

# =====================================================================================================
# EFFECTS TAB
# =====================================================================================================
t("tp_sec_audio", "Audio", "Audio", "Audio", "Dźwięk", "Audio", "Audio", "Audio")
t("tp_siren", "Tornado siren", "Tornadosirene", "Sirène de tornade", "Syrena tornadowa", "Sirena de tornado", "Sirena tornado",
  "Tornadosirene")
t("tp_tip_siren", "Play the tornado siren when a storm spawns.", "Spielt die Tornadosirene, wenn ein Sturm entsteht.",
  "Joue la sirène de tornade à l'apparition d'une tempête.", "Odtwarza syrenę, gdy pojawia się burza.",
  "Hace sonar la sirena cuando aparece una tormenta.", "Suona la sirena quando compare una tempesta.",
  "Speelt de tornadosirene af wanneer een storm ontstaat.")
t("tp_sec_visuals", "Visuals", "Optik", "Visuels", "Wygląd", "Visuales", "Grafica", "Beeld")
t("tp_ring", "Danger zone ring", "Gefahrenzonen-Ring", "Anneau de zone dangereuse", "Pierścień strefy zagrożenia",
  "Anillo de zona de peligro", "Anello zona di pericolo", "Ring gevarenzone")
t("tp_tip_ring", "Draw the red danger-zone ring around the tornado.", "Zeichnet den roten Gefahrenzonen-Ring um den Tornado.",
  "Affiche l'anneau rouge de zone dangereuse autour de la tornade.", "Rysuje czerwony pierścień strefy zagrożenia wokół tornada.",
  "Dibuja el anillo rojo de zona de peligro alrededor del tornado.", "Disegna l'anello rosso della zona di pericolo attorno al tornado.",
  "Tekent de rode gevarenzone-ring rond de tornado.")
t("tp_fire", "Random fire", "Zufälliges Feuer", "Feu aléatoire", "Losowy pożar", "Fuego aleatorio", "Fuoco casuale", "Willekeurig vuur")
t("tp_tip_fire", "On: damaged engines have a 50/50 chance to catch fire. Off: every damaged engine burns.",
  "An: Beschädigte Motoren fangen mit 50/50-Chance Feuer. Aus: Jeder beschädigte Motor brennt.",
  "Activé : les moteurs endommagés ont une chance sur deux de prendre feu. Désactivé : chaque moteur endommagé brûle.",
  "Wł.: uszkodzone silniki zapalają się z szansą 50/50. Wył.: każdy uszkodzony silnik płonie.",
  "Activado: los motores dañados tienen una probabilidad de 50/50 de arder. Desactivado: todos los motores dañados arden.",
  "Attivo: i motori danneggiati hanno una probabilità di 50/50 di prendere fuoco. Disattivo: ogni motore danneggiato brucia.",
  "Aan: beschadigde motoren hebben 50/50 kans om vlam te vatten. Uit: elke beschadigde motor brandt.")

# =====================================================================================================
# MODULES TAB
# =====================================================================================================
t("tp_sec_gameplay", "Gameplay", "Spielablauf", "Jouabilité", "Rozgrywka", "Jugabilidad", "Gameplay", "Gameplay")
t("tp_destruction", "Vehicle destruction", "Fahrzeugzerstörung", "Destruction des véhicules", "Niszczenie pojazdów",
  "Destrucción de vehículos", "Distruzione veicoli", "Voertuigvernietiging")
t("tp_tip_destruction", "Vehicles caught in the storm lose parts (auto-repaired after 24 in-game hours).",
  "Fahrzeuge im Sturm verlieren Teile (automatische Reparatur nach 24 Spielstunden).",
  "Les véhicules pris dans la tempête perdent des pièces (réparés automatiquement après 24 heures de jeu).",
  "Pojazdy w burzy tracą części (automatyczna naprawa po 24 godzinach gry).",
  "Los vehículos atrapados en la tormenta pierden piezas (se reparan solos tras 24 horas de juego).",
  "I veicoli nella tempesta perdono pezzi (riparati automaticamente dopo 24 ore di gioco).",
  "Voertuigen in de storm verliezen onderdelen (automatisch gerepareerd na 24 speluren).")
t("tp_recovery", "Hardcore recovery bill", "Harte Bergungsrechnung", "Facture de remorquage hardcore", "Rachunek za holowanie (hardcore)",
  "Factura de rescate hardcore", "Fattura di recupero hardcore", "Hardcore bergingsrekening")
t("tp_tip_recovery",
  "Charge an itemized tow and repair bill when a tornado-damaged vehicle is reset to the shop. Saved immediately.",
  "Stellt eine detaillierte Abschlepp- und Reparaturrechnung, wenn ein vom Tornado beschädigtes Fahrzeug zum Shop zurückgesetzt wird. Wird sofort gespeichert.",
  "Facture le remorquage et la réparation en détail quand un véhicule endommagé par la tornade est renvoyé au magasin. Enregistré immédiatement.",
  "Nalicza szczegółowy rachunek za holowanie i naprawę, gdy pojazd uszkodzony przez tornado wraca do sklepu. Zapisywane od razu.",
  "Cobra una factura detallada de remolque y reparación al devolver a la tienda un vehículo dañado por el tornado. Se guarda al instante.",
  "Addebita una fattura dettagliata di traino e riparazione quando un veicolo danneggiato dal tornado viene riportato al negozio. Salvato subito.",
  "Brengt een gespecificeerde sleep- en reparatierekening in rekening wanneer een door de tornado beschadigd voertuig naar de winkel wordt gezet. Direct opgeslagen.")
t("tp_money_scale", "Cost scale", "Kostenfaktor", "Échelle des coûts", "Skala kosztów", "Escala de costes",
  "Scala dei costi", "Kostenschaal")
t("tp_tip_money_scale",
  "Scales everything Tornado Physics charges, like the emergency tow bill. It is also adjusted automatically to the savegame's economic difficulty (Easy costs less than Hard).",
  "Skaliert alles, was Tornado Physics berechnet, z. B. die Abschlepprechnung. Wird zusätzlich automatisch an den wirtschaftlichen Schwierigkeitsgrad des Spielstands angepasst (Leicht kostet weniger als Schwer).",
  "Ajuste tout ce que Tornado Physics facture, comme la facture de remorquage. S'adapte aussi automatiquement à la difficulté économique de la partie (Facile coûte moins que Difficile).",
  "Skaluje wszystko, za co Tornado Physics pobiera opłaty, np. rachunek za holowanie. Dodatkowo automatycznie dostosowuje się do poziomu trudności ekonomicznej zapisu (Łatwy kosztuje mniej niż Trudny).",
  "Escala todo lo que cobra Tornado Physics, como la factura del remolque. También se ajusta automáticamente a la dificultad económica de la partida (Fácil cuesta menos que Difícil).",
  "Scala tutto ciò che Tornado Physics addebita, come la fattura del traino. Si adatta anche automaticamente alla difficoltà economica del salvataggio (Facile costa meno di Difficile).",
  "Schaalt alles wat Tornado Physics in rekening brengt, zoals de sleeprekening. Past zich ook automatisch aan de economische moeilijkheid van het spel aan (Makkelijk kost minder dan Moeilijk).")
t("tp_map_overlay", "Map overlay", "Karten-Overlay", "Superposition de carte", "Nakładka mapy", "Capa del mapa", "Overlay mappa",
  "Kaartoverlay")
t("tp_tip_mapui", "Show the tornado stats widget on the ESC map.", "Zeigt das Tornado-Infofeld auf der ESC-Karte.",
  "Affiche le widget des statistiques de la tornade sur la carte ESC.", "Pokazuje widżet statystyk tornada na mapie ESC.",
  "Muestra el widget de datos del tornado en el mapa ESC.", "Mostra il widget dei dati del tornado sulla mappa ESC.",
  "Toont de tornado-info op de ESC-kaart.")
t("tp_mapui_sel", "Only when selected", "Nur wenn ausgewählt", "Seulement si sélectionné", "Tylko po zaznaczeniu",
  "Solo al seleccionar", "Solo se selezionato", "Alleen indien geselecteerd")
t("tp_tip_mapui_sel", "Only show the overlay while the tornado hotspot is selected.",
  "Zeigt das Overlay nur, solange der Tornado-Hotspot ausgewählt ist.",
  "N'affiche la superposition que lorsque le point d'intérêt de la tornade est sélectionné.",
  "Pokazuje nakładkę tylko gdy znacznik tornada jest zaznaczony.",
  "Muestra la capa solo mientras el punto del tornado está seleccionado.",
  "Mostra l'overlay solo quando il punto del tornado è selezionato.",
  "Toont de overlay alleen als het tornadopunt is geselecteerd.")
t("tp_cargo", "Cargo spilling", "Ladungsverlust", "Perte de chargement", "Rozsypywanie ładunku", "Derrame de carga",
  "Perdita del carico", "Lading verliezen")
t("tp_tip_cargo", "Trailers caught in the storm dump their contents.", "Anhänger im Sturm verlieren ihre Ladung.",
  "Les remorques prises dans la tempête déversent leur contenu.", "Przyczepy w burzy rozsypują ładunek.",
  "Los remolques atrapados en la tormenta vierten su contenido.", "I rimorchi nella tempesta perdono il carico.",
  "Aanhangers in de storm verliezen hun lading.")
t("tp_spill_height", "Spill height", "Verlusthöhe", "Hauteur de déversement", "Wysokość rozsypywania", "Altura de derrame",
  "Altezza di perdita", "Morshoogte")
t("tp_tip_spill_height", "Minimum lift height before cargo starts to spill.", "Mindesthöhe, ab der Ladung verloren geht.",
  "Hauteur minimale avant que le chargement ne se déverse.", "Minimalna wysokość, od której ładunek się sypie.",
  "Altura mínima a partir de la cual se derrama la carga.", "Altezza minima oltre la quale il carico si perde.",
  "Minimale hoogte voordat lading begint te vallen.")
t("tp_spill_angle", "Spill angle", "Verlustwinkel", "Angle de déversement", "Kąt rozsypywania", "Ángulo de derrame",
  "Angolo di perdita", "Morshoek")
t("tp_tip_spill_angle", "Tilt (0-1) at which cargo spills.", "Neigung (0-1), ab der Ladung verloren geht.",
  "Inclinaison (0-1) à partir de laquelle le chargement se déverse.", "Przechył (0-1), przy którym ładunek się sypie.",
  "Inclinación (0-1) a la que se derrama la carga.", "Inclinazione (0-1) alla quale il carico si perde.",
  "Kanteling (0-1) waarbij lading valt.")
t("tp_drain", "Drain rate", "Verlustrate", "Vitesse de vidage", "Tempo ubywania", "Ritmo de vaciado", "Velocità di svuotamento",
  "Leegloopsnelheid")
t("tp_tip_drain", "How fast cargo is lost.", "Wie schnell Ladung verloren geht.", "Vitesse de perte du chargement.",
  "Jak szybko ubywa ładunku.", "Con qué rapidez se pierde la carga.", "Quanto velocemente si perde il carico.",
  "Hoe snel lading verloren gaat.")
t("tp_spread", "Spread radius", "Streuradius", "Rayon d'épandage", "Promień rozsypania", "Radio de dispersión",
  "Raggio di dispersione", "Spreidingsstraal")
t("tp_tip_spread", "Radius of the spilled cargo piles.", "Radius der verlorenen Ladungshaufen.", "Rayon des tas de chargement déversé.",
  "Promień kup rozsypanego ładunku.", "Radio de los montones de carga derramada.", "Raggio dei mucchi di carico perso.",
  "Straal van de gevallen ladinghopen.")
t("tp_leak", "Cover leak chance", "Leckchance mit Abdeckung", "Risque de fuite bâché", "Szansa przecieku plandeki",
  "Probabilidad de fuga con lona", "Probabilità di perdita con telone", "Lekkans met afdekking")
t("tp_tip_leak", "Chance (0-1) for covered trailers to leak or pop open.",
  "Chance (0-1), dass abgedeckte Anhänger lecken oder aufspringen.",
  "Probabilité (0-1) qu'une remorque bâchée fuie ou s'ouvre.",
  "Szansa (0-1), że przykryta przyczepa przecieknie lub się otworzy.",
  "Probabilidad (0-1) de que un remolque cubierto gotee o se abra.",
  "Probabilità (0-1) che un rimorchio coperto perda o si apra.",
  "Kans (0-1) dat een afgedekte aanhanger lekt of openspringt.")
t("tp_cargo_verbose", "Cargo verbose log", "Ausführliches Ladungsprotokoll", "Journal détaillé du chargement",
  "Szczegółowy dziennik ładunku", "Registro detallado de carga", "Log dettagliato del carico", "Uitgebreid ladinglog")
t("tp_tip_cargo_verbose", "Detailed cargo debug output in the log.", "Detaillierte Ladungs-Debugausgabe im Protokoll.",
  "Sortie de débogage détaillée du chargement dans le journal.", "Szczegółowe informacje debugowania ładunku w dzienniku.",
  "Salida de depuración detallada de la carga en el registro.", "Output di debug dettagliato del carico nel log.",
  "Gedetailleerde debuguitvoer van de lading in het log.")
t("tp_sec_livestock", "Livestock", "Nutztiere", "Bétail", "Inwentarz", "Ganado", "Bestiame", "Vee")
t("tp_husbandry", "Animal lethality", "Tödlichkeit für Tiere", "Létalité pour les animaux", "Śmiertelność zwierząt",
  "Letalidad para animales", "Letalità per gli animali", "Dodelijk voor dieren")
t("tp_tip_husbandry", "Tornadoes can kill animals in pastures that are not strictly indoors.",
  "Tornados können Tiere auf Weiden töten, die nicht vollständig im Stall sind.",
  "Les tornades peuvent tuer les animaux des pâturages qui ne sont pas entièrement à l'intérieur.",
  "Tornada mogą zabijać zwierzęta na pastwiskach, które nie są całkowicie zadaszone.",
  "Los tornados pueden matar animales en pastos que no están totalmente bajo techo.",
  "I tornado possono uccidere gli animali nei pascoli non completamente al chiuso.",
  "Tornado's kunnen dieren doden op weides die niet volledig binnen liggen.")
t("tp_immunity", "Post-impact immunity", "Schutzzeit nach Treffer", "Immunité après impact", "Odporność po uderzeniu",
  "Inmunidad tras impacto", "Immunità dopo l'impatto", "Immuniteit na treffer")
t("tp_tip_immunity", "Immunity time for a pasture after it was hit, for a 2 km map. Bigger maps scale it up (4 km = 2x, 8 km = 4x).",
  "Schutzzeit einer Weide, nachdem sie getroffen wurde, für eine 2-km-Karte. Größere Karten verlängern sie (4 km = 2x, 8 km = 4x).",
  "Durée d'immunité d'un pâturage après avoir été touché, pour une carte de 2 km. Les cartes plus grandes l'allongent (4 km = 2x, 8 km = 4x).",
  "Czas odporności pastwiska po uderzeniu, dla mapy 2 km. Większe mapy go wydłużają (4 km = 2x, 8 km = 4x).",
  "Tiempo de inmunidad de un pasto tras ser alcanzado, para un mapa de 2 km. Los mapas más grandes lo alargan (4 km = 2x, 8 km = 4x).",
  "Tempo di immunità di un pascolo dopo essere stato colpito, per una mappa di 2 km. Le mappe più grandi lo allungano (4 km = 2x, 8 km = 4x).",
  "Immuniteitstijd van een weide nadat die is geraakt, voor een kaart van 2 km. Grotere kaarten verlengen die (4 km = 2x, 8 km = 4x).")
t("tp_sec_traffic", "Road traffic", "Straßenverkehr", "Circulation routière", "Ruch drogowy", "Tráfico", "Traffico stradale", "Wegverkeer")
t("tp_traffic", "Traffic roadblocks", "Straßensperren", "Barrages routiers", "Blokady drogowe", "Controles de tráfico",
  "Blocchi stradali", "Wegversperringen")
t("tp_tip_traffic",
  "AI road traffic and pedestrians stop and wait (like at a red light) before entering the tornado. Cars and people already inside the zone leave it.",
  "KI-Straßenverkehr und Fußgänger halten vor dem Tornado an und warten (wie an einer roten Ampel). Autos und Personen, die schon in der Zone sind, verlassen sie.",
  "La circulation IA et les piétons s'arrêtent et attendent (comme à un feu rouge) avant d'entrer dans la tornade. Les voitures et personnes déjà dans la zone en sortent.",
  "Ruch AI i piesi zatrzymują się i czekają (jak na czerwonym świetle) przed wejściem w tornado. Auta i ludzie już w strefie ją opuszczają.",
  "El tráfico de IA y los peatones se detienen y esperan (como en un semáforo en rojo) antes de entrar en el tornado. Los coches y personas que ya están en la zona salen.",
  "Il traffico IA e i pedoni si fermano e attendono (come a un semaforo rosso) prima di entrare nel tornado. Auto e persone già nella zona ne escono.",
  "AI-verkeer en voetgangers stoppen en wachten (zoals bij rood licht) voordat ze de tornado in gaan. Auto's en mensen die al in de zone zijn, verlaten die.")
t("tp_traffic_buffer", "Stop distance", "Haltabstand", "Distance d'arrêt", "Odległość zatrzymania", "Distancia de parada",
  "Distanza di arresto", "Stopafstand")
t("tp_tip_traffic_buffer",
  "How far outside the tornado's outer radius cars and pedestrians stop. Turn on the danger ring (Effects tab) to see the roadblocks as red posts (yellow for pedestrians).",
  "Wie weit außerhalb des Tornadoradius Autos und Fußgänger halten. Mit dem Gefahrenring (Reiter Effekte) erscheinen die Sperren als rote Pfosten (gelb für Fußgänger).",
  "Distance au-delà du rayon de la tornade où voitures et piétons s'arrêtent. Activez l'anneau de danger (onglet Effets) pour voir les barrages en poteaux rouges (jaunes pour les piétons).",
  "Jak daleko poza promieniem tornada zatrzymują się auta i piesi. Włącz pierścień zagrożenia (zakładka Efekty), by zobaczyć blokady jako czerwone słupki (żółte dla pieszych).",
  "A qué distancia fuera del radio del tornado se detienen coches y peatones. Activa el anillo de peligro (pestaña Efectos) para ver los controles como postes rojos (amarillos para peatones).",
  "Quanto fuori dal raggio del tornado si fermano auto e pedoni. Attiva l'anello di pericolo (scheda Effetti) per vedere i blocchi come paletti rossi (gialli per i pedoni).",
  "Hoe ver buiten de tornadostraal auto's en voetgangers stoppen. Zet de gevarenring aan (tabblad Effecten) om de versperringen als rode palen te zien (geel voor voetgangers).")

t("tp_sec_wildlife", "Wildlife", "Wildtiere", "Faune sauvage", "Dzikie zwierzęta", "Fauna", "Fauna selvatica", "Wilde dieren")
t("tp_wildlife", "Wildlife flees the tornado", "Wildtiere fliehen vor dem Tornado", "La faune fuit la tornade",
  "Zwierzęta uciekają przed tornadem", "La fauna huye del tornado", "La fauna fugge dal tornado", "Wilde dieren vluchten voor de tornado")
t("tp_tip_wildlife",
  "Birds, deer, boar and other wild animals run or fly away from the tornado; animals it catches vanish. The farm dog runs home to its doghouse.",
  "Vögel, Rehe, Wildschweine und andere Wildtiere laufen oder fliegen vor dem Tornado davon; erfasste Tiere verschwinden. Der Hofhund läuft nach Hause zu seiner Hundehütte.",
  "Oiseaux, cerfs, sangliers et autres animaux sauvages fuient la tornade en courant ou en volant ; ceux qu'elle attrape disparaissent. Le chien de la ferme rentre à sa niche.",
  "Ptaki, sarny, dziki i inne dzikie zwierzęta uciekają przed tornadem; złapane przez nie znikają. Pies z farmy biegnie do swojej budy.",
  "Aves, ciervos, jabalíes y otros animales salvajes huyen corriendo o volando del tornado; los que atrapa desaparecen. El perro de la granja vuelve a su caseta.",
  "Uccelli, cervi, cinghiali e altri animali selvatici scappano dal tornado correndo o volando; quelli che cattura scompaiono. Il cane della fattoria torna alla sua cuccia.",
  "Vogels, herten, wilde zwijnen en andere wilde dieren rennen of vliegen weg van de tornado; dieren die hij grijpt verdwijnen. De boerderijhond rent naar zijn hondenhok.")
t("tp_wildlife_distance", "Flee distance", "Fluchtabstand", "Distance de fuite", "Odległość ucieczki", "Distancia de huida",
  "Distanza di fuga", "Vluchtafstand")
t("tp_tip_wildlife_distance", "How far outside the tornado's outer radius animals start to flee.",
  "Wie weit außerhalb des Tornadoradius Tiere zu fliehen beginnen.",
  "Distance au-delà du rayon de la tornade à partir de laquelle les animaux fuient.",
  "Jak daleko poza promieniem tornada zwierzęta zaczynają uciekać.",
  "A qué distancia fuera del radio del tornado empiezan a huir los animales.",
  "Quanto fuori dal raggio del tornado gli animali iniziano a fuggire.",
  "Hoe ver buiten de tornadostraal dieren beginnen te vluchten.")

t("tp_sec_hazards", "Natural hazards", "Naturgefahren", "Risques naturels", "Zagrożenia naturalne", "Riesgos naturales",
  "Rischi naturali", "Natuurrisico's")
t("tp_hazards", "Enable natural hazards", "Naturgefahren aktivieren", "Activer les risques naturels",
  "Włącz zagrożenia naturalne", "Activar riesgos naturales", "Attiva rischi naturali", "Natuurrisico's inschakelen")
t("tp_tip_hazards",
  "Weather can hurt your crops: long dry spells cause drought damage, heavy rain on soaked soil floods low-lying fields, and during a hot drought ripe fields can catch fire. Crop damage needs the game's disaster destruction setting. Off while FS25_RealisticWeather is installed.",
  "Das Wetter kann deinen Pflanzen schaden: Lange Trockenphasen verursachen Dürreschäden, Starkregen auf nassem Boden überflutet tief liegende Felder, und bei heißer Dürre können reife Felder in Brand geraten. Ernteschäden brauchen die Spieleinstellung für Katastrophenzerstörung. Aus, solange FS25_RealisticWeather installiert ist.",
  "La météo peut abîmer vos cultures : les longues périodes sèches causent des dégâts de sécheresse, les fortes pluies sur un sol détrempé inondent les champs bas, et lors d'une sécheresse chaude les champs mûrs peuvent prendre feu. Les dégâts aux cultures nécessitent l'option de destruction par catastrophes du jeu. Désactivé si FS25_RealisticWeather est installé.",
  "Pogoda może szkodzić uprawom: długie okresy bez deszczu powodują szkody od suszy, ulewy na nasiąkniętej glebie zalewają nisko położone pola, a podczas upalnej suszy dojrzałe pola mogą się zapalić. Szkody w uprawach wymagają włączonej opcji niszczenia przez katastrofy. Wyłączone, gdy zainstalowano FS25_RealisticWeather.",
  "El tiempo puede dañar tus cultivos: los periodos secos largos causan daños por sequía, las lluvias fuertes sobre suelo empapado inundan los campos bajos y, en una sequía calurosa, los campos maduros pueden incendiarse. Los daños necesitan la opción de destrucción por catástrofes del juego. Desactivado si FS25_RealisticWeather está instalado.",
  "Il meteo può danneggiare le colture: i lunghi periodi secchi causano danni da siccità, le piogge forti su terreno zuppo allagano i campi bassi e, durante una siccità torrida, i campi maturi possono prendere fuoco. I danni richiedono l'opzione di distruzione da catastrofi del gioco. Disattivato se FS25_RealisticWeather è installato.",
  "Het weer kan je gewassen schaden: lange droge periodes geven droogteschade, hevige regen op doorweekte grond zet laaggelegen velden onder water, en tijdens een hete droogte kunnen rijpe velden in brand vliegen. Gewasschade vereist de spelinstelling voor rampvernietiging. Uit zolang FS25_RealisticWeather geïnstalleerd is.")
t("tp_hazards_drought", "Drought", "Dürre", "Sécheresse", "Susza", "Sequía", "Siccità", "Droogte")
t("tp_tip_hazards_drought",
  "Long hot dry spells dry out the soil; growing crops then lose a little more every day until it rains. Rice paddies are spared.",
  "Lange heiße Trockenphasen trocknen den Boden aus; wachsende Pflanzen verlieren dann jeden Tag etwas mehr, bis es regnet. Reisfelder bleiben verschont.",
  "Les longues périodes chaudes et sèches assèchent le sol ; les cultures en croissance perdent alors un peu plus chaque jour jusqu'à la pluie. Les rizières sont épargnées.",
  "Długie upalne okresy bez deszczu wysuszają glebę; rosnące uprawy tracą wtedy codziennie trochę więcej, aż spadnie deszcz. Pola ryżowe są oszczędzone.",
  "Los periodos largos de calor y sequía secan el suelo; los cultivos en crecimiento pierden un poco más cada día hasta que llueve. Los arrozales se salvan.",
  "Lunghi periodi caldi e asciutti seccano il terreno; le colture in crescita perdono ogni giorno un po' di più finché non piove. Le risaie sono risparmiate.",
  "Lange hete droge periodes drogen de bodem uit; groeiende gewassen verliezen dan elke dag iets meer tot het regent. Rijstvelden blijven gespaard.")
t("tp_hazards_flood", "Flood", "Überschwemmung", "Inondation", "Powódź", "Inundación", "Alluvione", "Overstroming")
t("tp_tip_hazards_flood",
  "Several hours of heavy rain on already soaked soil flood the lowest-lying growing fields: water pools at each field's lowest point and drowns the crop there. Rice paddies are spared.",
  "Mehrere Stunden Starkregen auf bereits nassem Boden überfluten die am tiefsten liegenden Felder: Das Wasser sammelt sich am tiefsten Punkt jedes Feldes und ertränkt dort die Pflanzen. Reisfelder bleiben verschont.",
  "Plusieurs heures de fortes pluies sur un sol déjà détrempé inondent les champs les plus bas : l'eau s'accumule au point le plus bas de chaque champ et y noie la culture. Les rizières sont épargnées.",
  "Kilka godzin ulewy na już nasiąkniętej glebie zalewa najniżej położone pola: woda zbiera się w najniższym punkcie każdego pola i niszczy tam uprawy. Pola ryżowe są oszczędzone.",
  "Varias horas de lluvia fuerte sobre un suelo ya empapado inundan los campos más bajos: el agua se acumula en el punto más bajo de cada campo y ahoga allí el cultivo. Los arrozales se salvan.",
  "Diverse ore di pioggia forte su un terreno già zuppo allagano i campi più bassi: l'acqua si raccoglie nel punto più basso di ogni campo e lì annega la coltura. Le risaie sono risparmiate.",
  "Een paar uur hevige regen op al doorweekte grond zet de laagst gelegen velden onder water: het water verzamelt zich op het laagste punt van elk veld en verdrinkt daar het gewas. Rijstvelden blijven gespaard.")
t("tp_hazards_fire", "Field fire", "Feldbrand", "Feu de champ", "Pożar pola", "Incendio de campo", "Incendio dei campi",
  "Veldbrand")
t("tp_tip_hazards_fire",
  "During a drought, on hot dry afternoons, a ripe grain-type field can catch fire. The fire spreads inside the field and burns the crop until it burns out or rain puts it out. Marked on the map.",
  "Während einer Dürre kann an heißen, trockenen Nachmittagen ein reifes Getreidefeld in Brand geraten. Das Feuer breitet sich im Feld aus und verbrennt die Pflanzen, bis es ausbrennt oder Regen es löscht. Auf der Karte markiert.",
  "Pendant une sécheresse, par des après-midi chauds et secs, un champ mûr de type céréale peut prendre feu. Le feu se propage dans le champ et brûle la culture jusqu'à s'éteindre seul ou sous la pluie. Indiqué sur la carte.",
  "Podczas suszy, w upalne i suche popołudnia, dojrzałe pole zbożowe może się zapalić. Ogień rozprzestrzenia się po polu i pali uprawę, aż się wypali lub zgasi go deszcz. Zaznaczony na mapie.",
  "Durante una sequía, en tardes calurosas y secas, un campo maduro de cereal puede incendiarse. El fuego se extiende por el campo y quema el cultivo hasta apagarse solo o con la lluvia. Marcado en el mapa.",
  "Durante una siccità, nei pomeriggi caldi e secchi, un campo maturo di cereali può prendere fuoco. L'incendio si estende nel campo e brucia la coltura finché si spegne da solo o con la pioggia. Segnato sulla mappa.",
  "Tijdens een droogte kan een rijp graanveld op hete droge middagen in brand vliegen. Het vuur verspreidt zich door het veld en verbrandt het gewas tot het uitbrandt of de regen het dooft. Aangegeven op de kaart.")
t("tp_hazards_owned", "Only damage owned fields", "Nur eigene Felder beschädigen", "Seulement les champs possédés",
  "Tylko posiadane pola", "Solo campos con dueño", "Solo campi posseduti", "Alleen velden met eigenaar")
t("tp_tip_hazards_owned",
  "ON: drought and floods only damage fields a farm owns; fields nobody owns stay untouched. OFF: the weather hits every growing field on the map.",
  "AN: Dürre und Überschwemmungen beschädigen nur Felder, die einem Hof gehören; Felder ohne Besitzer bleiben unberührt. AUS: Das Wetter trifft jedes wachsende Feld der Karte.",
  "OUI : la sécheresse et les inondations n'abîment que les champs possédés par une ferme ; les champs sans propriétaire restent intacts. NON : la météo touche tous les champs en culture de la carte.",
  "WŁ.: susza i powodzie niszczą tylko pola należące do gospodarstwa; pola bez właściciela pozostają nietknięte. WYŁ.: pogoda trafia w każde uprawiane pole na mapie.",
  "SÍ: la sequía y las inundaciones solo dañan campos que pertenecen a una granja; los campos sin dueño no se tocan. NO: el tiempo afecta a todos los campos cultivados del mapa.",
  "SÌ: siccità e alluvioni danneggiano solo i campi posseduti da una fattoria; i campi senza proprietario restano intatti. NO: il meteo colpisce ogni campo coltivato della mappa.",
  "AAN: droogte en overstromingen beschadigen alleen velden van een boerderij; velden zonder eigenaar blijven ongemoeid. UIT: het weer treft elk groeiend veld op de kaart.")
t("tp_hazards_intensity", "Crop damage strength", "Stärke der Ernteschäden", "Force des dégâts aux cultures",
  "Siła szkód w uprawach", "Intensidad de los daños", "Intensità dei danni", "Sterkte van de gewasschade")
t("tp_tip_hazards_intensity",
  "100 % = mild: a long drought then costs a field about 15 %. Higher values hurt more.",
  "100 % = mild: Eine lange Dürre kostet ein Feld dann etwa 15 %. Höhere Werte richten mehr Schaden an.",
  "100 % = modéré : une longue sécheresse coûte alors à un champ environ 15 % ; des valeurs plus élevées font plus de dégâts.",
  "100 % = łagodnie: długa susza kosztuje wtedy pole około 15 %. Wyższe wartości szkodzą bardziej.",
  "100 % = suave: una sequía larga cuesta entonces a un campo un 15 %. Valores más altos dañan más.",
  "100 % = lieve: una lunga siccità costa allora a un campo circa il 15 %. Valori più alti fanno più danni.",
  "100 % = mild: een lange droogte kost een veld dan ongeveer 15 %. Hogere waarden doen meer schade.")
t("tp_hazards_frequency", "Dry-spell frequency", "Häufigkeit von Trockenphasen", "Fréquence des périodes sèches",
  "Częstotliwość okresów suszy", "Frecuencia de periodos secos", "Frequenza dei periodi secchi", "Frequentie van droge periodes")
t("tp_tip_hazards_frequency",
  "How fast the soil dries out in warm weather. Higher = more and longer droughts.",
  "Wie schnell der Boden bei warmem Wetter austrocknet. Höher = mehr und längere Dürren.",
  "Vitesse à laquelle le sol s'assèche par temps chaud. Plus élevé = sécheresses plus fréquentes et plus longues.",
  "Jak szybko gleba wysycha przy ciepłej pogodzie. Wyżej = więcej i dłuższych susz.",
  "Lo rápido que se seca el suelo con tiempo cálido. Más alto = más sequías y más largas.",
  "Quanto velocemente il terreno si secca col caldo. Più alto = siccità più frequenti e più lunghe.",
  "Hoe snel de bodem uitdroogt bij warm weer. Hoger = meer en langere droogtes.")

# =====================================================================================================
# DEVELOPER TAB
# =====================================================================================================
t("tp_sec_overlays", "Overlays", "Einblendungen", "Superpositions", "Nakładki", "Superposiciones", "Overlay", "Overlays")
t("tp_hud", "Telemetry HUD", "Telemetrie-HUD", "HUD de télémétrie", "HUD telemetrii", "HUD de telemetría", "HUD telemetria",
  "Telemetrie-HUD")
t("tp_tip_hud", "Physics telemetry labels over every tracked object.", "Physik-Telemetrie über jedem erfassten Objekt.",
  "Étiquettes de télémétrie physique au-dessus de chaque objet suivi.", "Etykiety telemetrii fizyki nad każdym śledzonym obiektem.",
  "Etiquetas de telemetría física sobre cada objeto seguido.", "Etichette di telemetria fisica sopra ogni oggetto tracciato.",
  "Fysica-telemetrie boven elk gevolgd object.")
t("tp_pos", "Position tracking", "Positionsverfolgung", "Suivi de position", "Śledzenie pozycji", "Seguimiento de posición",
  "Tracciamento posizione", "Positie volgen")
t("tp_tip_pos", "Log the tornado node coordinates in real time.", "Protokolliert die Koordinaten des Tornados in Echtzeit.",
  "Enregistre les coordonnées de la tornade en temps réel.", "Zapisuje współrzędne tornada w czasie rzeczywistym.",
  "Registra las coordenadas del tornado en tiempo real.", "Registra le coordinate del tornado in tempo reale.",
  "Logt de coördinaten van de tornado in realtime.")
t("tp_sec_verbose", "Verbose logging", "Ausführliche Protokollierung", "Journalisation détaillée", "Szczegółowe logowanie",
  "Registro detallado", "Log dettagliato", "Uitgebreide logging")
t("tp_verbose_all", "All channels", "Alle Kanäle", "Tous les canaux", "Wszystkie kanały", "Todos los canales", "Tutti i canali",
  "Alle kanalen")
t("tp_tip_verbose_all", "Master switch. Also sets the destruction and physics channels.",
  "Hauptschalter. Schaltet auch die Kanäle Zerstörung und Physik.",
  "Interrupteur principal. Active aussi les canaux destruction et physique.",
  "Główny przełącznik. Ustawia też kanały zniszczeń i fizyki.",
  "Interruptor principal. También activa los canales de destrucción y física.",
  "Interruttore principale. Imposta anche i canali distruzione e fisica.",
  "Hoofdschakelaar. Zet ook de kanalen vernietiging en fysica.")
t("tp_tip_verbose_physics", "Suction / ejection logging.", "Protokoll von Sog / Auswurf.", "Journal de l'aspiration / éjection.",
  "Logowanie zasysania / wyrzutu.", "Registro de succión / expulsión.", "Log di aspirazione / espulsione.", "Logging van zuigen / uitwerpen.")
t("tp_verbose_destruction", "Destruction", "Zerstörung", "Destruction", "Zniszczenia", "Destrucción", "Distruzione", "Vernietiging")
t("tp_tip_verbose_destruction", "Save / load / repair logging of the destruction module.",
  "Protokoll zu Speichern / Laden / Reparatur des Zerstörungsmoduls.",
  "Journal de sauvegarde / chargement / réparation du module de destruction.",
  "Logowanie zapisu / wczytywania / napraw modułu zniszczeń.",
  "Registro de guardado / carga / reparación del módulo de destrucción.",
  "Log di salvataggio / caricamento / riparazione del modulo distruzione.",
  "Logging van opslaan / laden / repareren van de vernietigingsmodule.")
t("tp_verbose_indoor", "Indoor bypass", "Innenraum-Umgehung", "Contournement intérieur", "Pomijanie wnętrz", "Omisión interior",
  "Bypass interni", "Binnenomzeiling")
t("tp_tip_verbose_indoor", "Indoor bypass checks. Very noisy.", "Prüfungen der Innenraum-Umgehung. Sehr viele Meldungen.",
  "Vérifications du contournement intérieur. Très verbeux.", "Sprawdzanie pomijania wnętrz. Bardzo dużo wpisów.",
  "Comprobaciones de omisión interior. Muy ruidoso.", "Controlli del bypass interni. Molto verboso.",
  "Controles van binnenomzeiling. Zeer veel meldingen.")
t("tp_sec_diagnostics", "Diagnostics (output goes to the log)", "Diagnose (Ausgabe im Protokoll)", "Diagnostic (sortie dans le journal)",
  "Diagnostyka (wynik w dzienniku)", "Diagnóstico (salida en el registro)", "Diagnostica (output nel log)", "Diagnose (uitvoer in het log)")
t("tp_btn_print", "Print", "Ausgeben", "Afficher", "Wypisz", "Mostrar", "Stampa", "Tonen")
t("tp_dev_status", "Status summary", "Statusübersicht", "Résumé de l'état", "Podsumowanie stanu", "Resumen de estado",
  "Riepilogo stato", "Statusoverzicht")
t("tp_btn_dump", "Dump", "Ausgeben", "Exporter", "Zrzut", "Volcar", "Dump", "Dump")
t("tp_dev_hotspot", "Hotspot state", "Hotspot-Status", "État du point d'intérêt", "Stan znacznika", "Estado del punto",
  "Stato del punto", "Status hotspot")
t("tp_dev_mapui", "Map overlay state", "Status Karten-Overlay", "État de la superposition", "Stan nakładki mapy",
  "Estado de la capa del mapa", "Stato overlay mappa", "Status kaartoverlay")
t("tp_btn_run", "Run", "Starten", "Lancer", "Uruchom", "Ejecutar", "Avvia", "Starten")
t("tp_dev_kill_test", "Husbandry kill test", "Tierhaltungs-Tötungstest", "Test de létalité d'élevage", "Test śmiertelności hodowli",
  "Prueba de letalidad ganadera", "Test letalità allevamento", "Veeteelt-dodingstest")
t("tp_confirm_kill_test", "Run the husbandry kill test? Animals in every outdoor pasture within 60 m of you WILL be killed.",
  "Tierhaltungs-Tötungstest starten? Tiere auf jeder Außenweide im Umkreis von 60 m WERDEN getötet.",
  "Lancer le test de létalité ? Les animaux de chaque pâturage extérieur à moins de 60 m SERONT tués.",
  "Uruchomić test śmiertelności? Zwierzęta na każdym pastwisku w promieniu 60 m ZGINĄ.",
  "¿Ejecutar la prueba de letalidad? Los animales de cada pasto exterior a menos de 60 m MORIRÁN.",
  "Avviare il test di letalità? Gli animali di ogni pascolo all'aperto entro 60 m VERRANNO uccisi.",
  "De dodingstest starten? Dieren op elke buitenweide binnen 60 m WORDEN gedood.")

# =====================================================================================================
# IN-GAME MESSAGES
# =====================================================================================================
t("tp_msg_touchdown", "ALERT: TORNADO TOUCHDOWN! (EF-%d | Radius: %dm | Power: x%.1f)",
  "ALARM: TORNADO HAT DEN BODEN ERREICHT! (EF-%d | Radius: %dm | Stärke: x%.1f)",
  "ALERTE : UNE TORNADE A TOUCHÉ LE SOL ! (EF-%d | Rayon : %dm | Puissance : x%.1f)",
  "ALARM: TORNADO DOTKNĘŁO ZIEMI! (EF-%d | Promień: %dm | Siła: x%.1f)",
  "¡ALERTA: UN TORNADO HA TOCADO TIERRA! (EF-%d | Radio: %dm | Fuerza: x%.1f)",
  "ALLARME: UN TORNADO HA TOCCATO TERRA! (EF-%d | Raggio: %dm | Potenza: x%.1f)",
  "ALARM: TORNADO HEEFT DE GROND GERAAKT! (EF-%d | Straal: %dm | Kracht: x%.1f)")
t("tp_msg_outbreak", "TORNADO OUTBREAK (%s): up to %d more tornadoes possible today!",
  "TORNADO-AUSBRUCH (%s): heute sind bis zu %d weitere Tornados möglich!",
  "ÉPISODE DE TORNADES (%s) : jusqu'à %d autres tornades possibles aujourd'hui !",
  "WYBUCH TORNAD (%s): dziś możliwe jeszcze do %d tornad!",
  "BROTE DE TORNADOS (%s): ¡hoy son posibles hasta %d tornados más!",
  "FOCOLAIO DI TORNADO (%s): oggi sono possibili fino a %d altri tornado!",
  "TORNADO-UITBRAAK (%s): vandaag nog tot %d tornado's mogelijk!")
t("tp_msg_dry_spell", "DRY SPELL: soil moisture is down to %d %%. Crops will suffer if it stays dry.",
  "TROCKENPHASE: Die Bodenfeuchte ist auf %d %% gesunken. Bleibt es trocken, leiden die Pflanzen.",
  "PÉRIODE SÈCHE : l'humidité du sol est tombée à %d %%. Les cultures souffriront si le temps reste sec.",
  "OKRES SUCHY: wilgotność gleby spadła do %d %%. Uprawy ucierpią, jeśli nadal nie będzie padać.",
  "PERIODO SECO: la humedad del suelo ha bajado al %d %%. Los cultivos sufrirán si sigue sin llover.",
  "PERIODO SECCO: l'umidità del suolo è scesa al %d %%. Le colture soffriranno se non piove.",
  "DROGE PERIODE: de bodemvochtigheid is gedaald tot %d %%. Gewassen lijden als het droog blijft.")
t("tp_msg_drought_start", "DROUGHT! The soil has dried out - growing crops are suffering.",
  "DÜRRE! Der Boden ist ausgetrocknet - wachsende Pflanzen leiden.",
  "SÉCHERESSE ! Le sol est desséché - les cultures en croissance souffrent.",
  "SUSZA! Gleba wyschła - rosnące uprawy cierpią.",
  "¡SEQUÍA! El suelo se ha secado: los cultivos en crecimiento sufren.",
  "SICCITÀ! Il terreno si è seccato: le colture in crescita soffrono.",
  "DROOGTE! De bodem is uitgedroogd - groeiende gewassen lijden.")
t("tp_msg_drought_damage", "DROUGHT DAMAGE: %d of your fields lost crop today.",
  "DÜRRESCHADEN: %d deiner Felder haben heute Ertrag verloren.",
  "DÉGÂTS DE SÉCHERESSE : %d de vos champs ont perdu une partie de leur culture aujourd'hui.",
  "SZKODY OD SUSZY: %d twoich pól straciło dziś część plonu.",
  "DAÑOS POR SEQUÍA: %d de tus campos han perdido cosecha hoy.",
  "DANNI DA SICCITÀ: %d dei tuoi campi hanno perso raccolto oggi.",
  "DROOGTESCHADE: %d van je velden zijn vandaag oogst kwijtgeraakt.")
t("tp_msg_flood", "FLOODING! Heavy rain on waterlogged ground has flooded %d low-lying fields.",
  "ÜBERSCHWEMMUNG! Starkregen auf durchnässtem Boden hat %d tief liegende Felder überflutet.",
  "INONDATION ! De fortes pluies sur un sol détrempé ont inondé %d champs situés en contrebas.",
  "POWÓDŹ! Ulewa na podmokłej glebie zalała %d nisko położonych pól.",
  "¡INUNDACIÓN! La lluvia fuerte sobre suelo encharcado ha inundado %d campos bajos.",
  "ALLUVIONE! La pioggia forte su terreno fradicio ha allagato %d campi bassi.",
  "OVERSTROMING! Hevige regen op doorweekte grond heeft %d laaggelegen velden onder water gezet.")
t("tp_msg_flood_damage", "FLOOD DAMAGE: %d of your fields are under water.",
  "ÜBERSCHWEMMUNGSSCHADEN: %d deiner Felder stehen unter Wasser.",
  "DÉGÂTS D'INONDATION : %d de vos champs sont sous l'eau.",
  "SZKODY POWODZIOWE: %d twoich pól jest pod wodą.",
  "DAÑOS POR INUNDACIÓN: %d de tus campos están bajo el agua.",
  "DANNI DA ALLUVIONE: %d dei tuoi campi sono sott'acqua.",
  "OVERSTROMINGSSCHADE: %d van je velden staan onder water.")
t("tp_msg_field_fire", "FIELD FIRE on field %s! The dry crop is burning.",
  "FELDBRAND auf Feld %s! Die trockenen Pflanzen brennen.",
  "FEU DE CHAMP sur le champ %s ! La culture sèche brûle.",
  "POŻAR POLA na polu %s! Sucha uprawa płonie.",
  "¡INCENDIO DE CAMPO en el campo %s! El cultivo seco está ardiendo.",
  "INCENDIO DEL CAMPO %s! La coltura secca sta bruciando.",
  "VELDBRAND op veld %s! Het droge gewas staat in brand.")
t("tp_msg_fire_out_rain", "The rain has put out the fire on field %s.",
  "Der Regen hat den Brand auf Feld %s gelöscht.",
  "La pluie a éteint le feu sur le champ %s.",
  "Deszcz ugasił pożar na polu %s.",
  "La lluvia ha apagado el incendio del campo %s.",
  "La pioggia ha spento l'incendio del campo %s.",
  "De regen heeft de brand op veld %s gedoofd.")
t("tp_msg_fire_out", "The fire on field %s has burned out.",
  "Der Brand auf Feld %s ist ausgebrannt.",
  "Le feu sur le champ %s s'est éteint de lui-même.",
  "Pożar na polu %s wypalił się.",
  "El incendio del campo %s se ha consumido.",
  "L'incendio del campo %s si è esaurito.",
  "De brand op veld %s is uitgebrand.")
t("tp_hotspot_field_fire", "Field fire (field %s)", "Feldbrand (Feld %s)", "Feu de champ (champ %s)", "Pożar pola (pole %s)",
  "Incendio de campo (campo %s)", "Incendio (campo %s)", "Veldbrand (veld %s)")
t("tp_msg_drought_end", "The drought is over - rain has refilled the soil.",
  "Die Dürre ist vorbei - Regen hat den Boden wieder aufgefüllt.",
  "La sécheresse est terminée - la pluie a rechargé le sol.",
  "Susza się skończyła - deszcz nawodnił glebę.",
  "La sequía ha terminado: la lluvia ha recargado el suelo.",
  "La siccità è finita: la pioggia ha ricaricato il terreno.",
  "De droogte is voorbij - regen heeft de bodem weer aangevuld.")
t("tp_msg_outbreak_one", "TORNADO OUTBREAK (%s): one more tornado possible today!",
  "TORNADO-AUSBRUCH (%s): heute ist noch ein weiterer Tornado möglich!",
  "ÉPISODE DE TORNADES (%s) : encore une tornade possible aujourd'hui !",
  "WYBUCH TORNAD (%s): dziś możliwe jeszcze jedno tornado!",
  "BROTE DE TORNADOS (%s): ¡hoy es posible un tornado más!",
  "FOCOLAIO DI TORNADO (%s): oggi è possibile un altro tornado!",
  "TORNADO-UITBRAAK (%s): vandaag nog één tornado mogelijk!")
t("tp_msg_storm_damage", "STORM DAMAGE: %s (%s) lost %d animals! Safe for %d seconds.",
  "STURMSCHADEN: %s (%s) hat %d Tiere verloren! %d Sekunden lang geschützt.",
  "DÉGÂTS DE TEMPÊTE : %s (%s) a perdu %d animaux ! En sécurité pendant %d secondes.",
  "SZKODY OD BURZY: %s (%s) straciło %d zwierząt! Bezpieczne przez %d sekund.",
  "DAÑOS DE TORMENTA: ¡%s (%s) ha perdido %d animales! A salvo durante %d segundos.",
  "DANNI DA TEMPESTA: %s (%s) ha perso %d animali! Al sicuro per %d secondi.",
  "STORMSCHADE: %s (%s) heeft %d dieren verloren! %d seconden veilig.")
t("tp_pen_pasture", "Pasture", "Weide", "Pâturage", "Pastwisko", "Pasto", "Pascolo", "Weide")
t("tp_pen_meadow", "Meadow", "Wiese", "Prairie", "Łąka", "Prado", "Prato", "Weiland")
t("tp_pen_fence", "Fenced pen", "Gehege", "Enclos", "Zagroda", "Cercado", "Recinto", "Omheining")
t("tp_msg_tow_bill", "EMERGENCY TOW: billed %s (tow %s, %d broken parts, vehicle value %s)",
  "NOTFALL-ABSCHLEPPDIENST: %s berechnet (Abschleppen %s, %d kaputte Teile, Fahrzeugwert %s)",
  "REMORQUAGE D'URGENCE : %s facturés (remorquage %s, %d pièces cassées, valeur du véhicule %s)",
  "HOLOWANIE AWARYJNE: naliczono %s (holowanie %s, %d zniszczonych części, wartość pojazdu %s)",
  "REMOLQUE DE EMERGENCIA: facturado %s (remolque %s, %d piezas rotas, valor del vehículo %s)",
  "TRAINO DI EMERGENZA: addebitati %s (traino %s, %d pezzi rotti, valore del veicolo %s)",
  "NOODSLEEPDIENST: %s in rekening gebracht (slepen %s, %d kapotte onderdelen, voertuigwaarde %s)")
# Same bill with engine work: the bill text with ", <engine work>)" in place of its closing ")".
_engine = {"en": "engine work %s", "de": "Motorarbeiten %s", "fr": "travaux moteur %s", "pl": "naprawa silnika %s",
           "es": "trabajo de motor %s", "it": "lavori al motore %s", "nl": "motorwerk %s"}
t("tp_msg_tow_bill_engine", *[T["tp_msg_tow_bill"][l][:-1] + ", " + _engine[l] + ")" for l in LANGUAGES])

# =====================================================================================================
# ESC MAP OVERLAY / HOTSPOT
# =====================================================================================================
t("tp_map_line", "EF:%d  Wind:%d-%d mph  Radius:%d m  Distance:%s", "EF:%d  Wind:%d-%d mph  Radius:%d m  Entfernung:%s",
  "EF:%d  Vent:%d-%d mph  Rayon:%d m  Distance:%s", "EF:%d  Wiatr:%d-%d mph  Promień:%d m  Odległość:%s",
  "EF:%d  Viento:%d-%d mph  Radio:%d m  Distancia:%s", "EF:%d  Vento:%d-%d mph  Raggio:%d m  Distanza:%s",
  "EF:%d  Wind:%d-%d mph  Straal:%d m  Afstand:%s")
t("tp_hotspot_title", "EF:%d  Wind:%s  Radius:%s  Distance:%s", "EF:%d  Wind:%s  Radius:%s  Entfernung:%s",
  "EF:%d  Vent:%s  Rayon:%s  Distance:%s", "EF:%d  Wiatr:%s  Promień:%s  Odległość:%s",
  "EF:%d  Viento:%s  Radio:%s  Distancia:%s", "EF:%d  Vento:%s  Raggio:%s  Distanza:%s",
  "EF:%d  Wind:%s  Straal:%s  Afstand:%s")
t("tp_map_storm", "Storm: %s", "Unwetter: %s", "Orage : %s", "Burza: %s", "Tormenta: %s", "Temporale: %s", "Onweer: %s")
t("tp_map_hail", "Hail: %s", "Hagel: %s", "Grêle : %s", "Grad: %s", "Granizo: %s", "Grandine: %s", "Hagel: %s")
t("tp_map_gusts", "Gusts: %d km/h", "Böen: %d km/h", "Rafales : %d km/h", "Porywy: %d km/h", "Rachas: %d km/h",
  "Raffiche: %d km/h", "Windstoten: %d km/h")
t("tp_map_moving", "Moving: %s", "Zugrichtung: %s", "Direction : %s", "Kierunek: %s", "Dirección: %s", "Direzione: %s", "Richting: %s")
t("tp_supercell_lp", "LP supercell", "LP-Superzelle", "Supercellule LP", "Superkomórka LP", "Supercélula LP", "Supercella LP",
  "LP-supercel")
t("tp_supercell_classic", "Classic supercell", "Klassische Superzelle", "Supercellule classique", "Klasyczna superkomórka",
  "Supercélula clásica", "Supercella classica", "Klassieke supercel")
t("tp_supercell_hp", "HP supercell", "HP-Superzelle", "Supercellule HP", "Superkomórka HP", "Supercélula HP", "Supercella HP",
  "HP-supercel")

# Compass directions (where the tornado is moving)
for code, en, de, fr, pl, es, it, nl in [
    ("N", "N", "N", "N", "Pn", "N", "N", "N"),
    ("NE", "NE", "NO", "NE", "Pn-Wsch", "NE", "NE", "NO"),
    ("E", "E", "O", "E", "Wsch", "E", "E", "O"),
    ("SE", "SE", "SO", "SE", "Pd-Wsch", "SE", "SE", "ZO"),
    ("S", "S", "S", "S", "Pd", "S", "S", "Z"),
    ("SW", "SW", "SW", "SO", "Pd-Zach", "SO", "SO", "ZW"),
    ("W", "W", "W", "O", "Zach", "O", "O", "W"),
    ("NW", "NW", "NW", "NO", "Pn-Zach", "NO", "NO", "NW"),
]:
    t("tp_dir_" + code, en, de, fr, pl, es, it, nl)
