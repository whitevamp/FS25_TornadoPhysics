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
t("tp_tab_messages", "Messages", "Nachrichten", "Messages", "Wiadomości", "Mensajes", "Messaggi", "Berichten")
t("tp_btn_save", "Save", "Speichern", "Enregistrer", "Zapisz", "Guardar", "Salva", "Opslaan")
t("tp_btn_remove", "Remove", "Entfernen", "Supprimer", "Usuń", "Quitar", "Rimuovi", "Verwijderen")
t("tp_msg_none", "No messages", "Keine Nachrichten", "Aucun message", "Brak wiadomości", "Sin mensajes", "Nessun messaggio",
  "Geen berichten")
t("tp_msg_day", "Day", "Tag", "Jour", "Dzień", "Día", "Giorno", "Dag")
t("tp_msg_saved_done", "Message saved.", "Nachricht gespeichert.", "Message enregistré.", "Wiadomość zapisana.",
  "Mensaje guardado.", "Messaggio salvato.", "Bericht opgeslagen.")
t("tp_msg_removed_done", "Saved message removed.", "Gespeicherte Nachricht entfernt.", "Message enregistré supprimé.",
  "Zapisana wiadomość usunięta.", "Mensaje guardado quitado.", "Messaggio salvato rimosso.", "Opgeslagen bericht verwijderd.")
t("tp_confirm_msg_remove", "Remove this saved message?", "Diese gespeicherte Nachricht entfernen?",
  "Supprimer ce message enregistré ?", "Usunąć tę zapisaną wiadomość?", "¿Quitar este mensaje guardado?",
  "Rimuovere questo messaggio salvato?", "Dit opgeslagen bericht verwijderen?")
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
t("tp_remove_bales", "Twister removes bales", "Twister entfernt Ballen", "La tornade supprime les balles", "Trąba usuwa bele",
  "El tornado elimina pacas", "Il tornado rimuove le balle", "Tornado verwijdert balen")
t("tp_tip_remove_bales",
  "On: the base game's twister rule - bales lying outside near the core are simply deleted (the base game has this on). Off (default): bales are never deleted, only thrown by the tornado physics.",
  "An: die Regel des Twisters im Grundspiel - Ballen draußen in Kernnähe werden einfach gelöscht (im Grundspiel immer an). Aus (Standard): Ballen werden nie gelöscht, nur von der Tornado-Physik geworfen.",
  "Activé : la règle de la tornade du jeu de base - les balles dehors près du cœur sont simplement supprimées (activé dans le jeu de base). Désactivé (par défaut) : les balles ne sont jamais supprimées, seulement projetées par la physique de la tornade.",
  "Wł.: zasada trąby z gry podstawowej - bele leżące na zewnątrz blisko rdzenia są po prostu usuwane (w grze podstawowej włączone). Wył. (domyślnie): bele nigdy nie są usuwane, tylko rzucane przez fizykę tornada.",
  "Activado: la regla del tornado del juego base - las pacas al aire libre cerca del núcleo se eliminan sin más (activado en el juego base). Desactivado (por defecto): las pacas nunca se eliminan, solo las lanza la física del tornado.",
  "Attivo: la regola del tornado del gioco base - le balle all'aperto vicino al nucleo vengono semplicemente eliminate (attivo nel gioco base). Disattivo (predefinito): le balle non vengono mai eliminate, solo lanciate dalla fisica del tornado.",
  "Aan: de regel van de tornado uit het basisspel - balen buiten dicht bij de kern worden gewoon verwijderd (in het basisspel aan). Uit (standaard): balen worden nooit verwijderd, alleen weggeslingerd door de tornadofysica.")
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
t("tp_fire", "Vehicle fires", "Fahrzeugbrände", "Incendies de véhicules", "Pożary pojazdów", "Incendios de vehículos",
  "Incendi dei veicoli", "Voertuigbranden")
t("tp_tip_fire",
  "On: a badly damaged engine can catch fire - the stronger the tornado, the likelier (5 percent at EF0 up to 45 percent at EF5, decided once per vehicle until it is repaired). A burned vehicle is a total loss for the insurance. Off: no vehicle fires.",
  "An: Ein schwer beschädigter Motor kann Feuer fangen - je stärker der Tornado, desto wahrscheinlicher (5 Prozent bei EF0 bis 45 Prozent bei EF5, einmal pro Fahrzeug entschieden, bis es repariert ist). Ein ausgebranntes Fahrzeug ist für die Versicherung ein Totalschaden. Aus: keine Fahrzeugbrände.",
  "Activé : un moteur gravement endommagé peut prendre feu - plus la tornade est forte, plus c'est probable (5 pour cent en EF0 jusqu'à 45 pour cent en EF5, décidé une fois par véhicule jusqu'à sa réparation). Un véhicule brûlé est une perte totale pour l'assurance. Désactivé : aucun incendie de véhicule.",
  "Wł.: mocno uszkodzony silnik może się zapalić - im silniejsze tornado, tym bardziej prawdopodobne (od 5 procent przy EF0 do 45 procent przy EF5, losowane raz na pojazd do jego naprawy). Spalony pojazd to dla ubezpieczenia szkoda całkowita. Wył.: brak pożarów pojazdów.",
  "Activado: un motor muy dañado puede incendiarse - cuanto más fuerte el tornado, más probable (del 5 por ciento en EF0 al 45 por ciento en EF5, decidido una vez por vehículo hasta que se repara). Un vehículo quemado es un siniestro total para el seguro. Desactivado: sin incendios de vehículos.",
  "Attivo: un motore gravemente danneggiato può prendere fuoco - più il tornado è forte, più è probabile (dal 5 per cento con EF0 al 45 per cento con EF5, deciso una volta per veicolo finché non viene riparato). Un veicolo bruciato è un danno totale per l'assicurazione. Disattivo: nessun incendio dei veicoli.",
  "Aan: een zwaar beschadigde motor kan vlam vatten - hoe sterker de tornado, hoe waarschijnlijker (5 procent bij EF0 tot 45 procent bij EF5, eenmaal per voertuig bepaald tot het gerepareerd is). Een uitgebrand voertuig is voor de verzekering total loss. Uit: geen voertuigbranden.")

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
# Insurance (phase 0: settings, money types, letters)
t("tp_sec_insurance", "Insurance", "Versicherung", "Assurance", "Ubezpieczenia", "Seguros", "Assicurazione", "Verzekering")
t("tp_insurance", "Enable insurance", "Versicherung aktivieren", "Activer l'assurance", "Włącz ubezpieczenia",
  "Activar seguros", "Attiva assicurazione", "Verzekering inschakelen")
t("tp_tip_insurance",
  "Per-farm insurance against tornado and weather damage: monthly premiums, claims and payouts, with the rules and prices of the map's country. Policies come in a later update; this switch prepares the system.",
  "Versicherung pro Hof gegen Tornado- und Wetterschäden: monatliche Prämien, Schadensfälle und Auszahlungen nach den Regeln und Preisen des Landes der Karte. Die Policen folgen in einem späteren Update; dieser Schalter bereitet das System vor.",
  "Assurance par ferme contre les dégâts des tornades et de la météo : primes mensuelles, sinistres et indemnités, avec les règles et les prix du pays de la carte. Les contrats arrivent dans une prochaine mise à jour ; cette option prépare le système.",
  "Ubezpieczenie dla każdego gospodarstwa od szkód po tornadach i pogodzie: miesięczne składki, szkody i wypłaty według zasad i cen kraju mapy. Polisy pojawią się w kolejnej aktualizacji; ten przełącznik przygotowuje system.",
  "Seguro por granja contra daños de tornados y del tiempo: primas mensuales, siniestros e indemnizaciones, con las reglas y precios del país del mapa. Las pólizas llegarán en una próxima actualización; esta opción prepara el sistema.",
  "Assicurazione per fattoria contro i danni di tornado e meteo: premi mensili, sinistri e risarcimenti, con le regole e i prezzi del paese della mappa. Le polizze arriveranno in un prossimo aggiornamento; questa opzione prepara il sistema.",
  "Verzekering per boerderij tegen tornado- en weerschade: maandelijkse premies, schademeldingen en uitkeringen, met de regels en prijzen van het land van de kaart. De polissen komen in een volgende update; deze schakelaar bereidt het systeem voor.")
t("tp_insurance_admin_only", "Only the admin manages policies", "Nur der Admin verwaltet Policen",
  "Seul l'admin gère les contrats", "Tylko admin zarządza polisami", "Solo el admin gestiona pólizas",
  "Solo l'admin gestisce le polizze", "Alleen de admin beheert polissen")
t("tp_tip_insurance_admin_only",
  "OFF: each farm's managers (and the server admin) buy, change and cancel their farm's policies. ON: only the server admin does - for servers where the admin runs the insurance.",
  "AUS: Die Verwalter jedes Hofs (und der Server-Admin) schließen die Policen ihres Hofs ab, ändern und kündigen sie. AN: Nur der Server-Admin - für Server, auf denen der Admin die Versicherung führt.",
  "NON : les gérants de chaque ferme (et l'admin du serveur) souscrivent, modifient et résilient les contrats de leur ferme. OUI : seul l'admin du serveur le fait - pour les serveurs où l'admin gère l'assurance.",
  "WYŁ.: zarządcy każdego gospodarstwa (i admin serwera) kupują, zmieniają i anulują polisy swojego gospodarstwa. WŁ.: robi to tylko admin serwera - dla serwerów, na których admin prowadzi ubezpieczenia.",
  "NO: los gestores de cada granja (y el admin del servidor) contratan, cambian y cancelan las pólizas de su granja. SÍ: solo lo hace el admin del servidor, para servidores donde el admin lleva los seguros.",
  "NO: i gestori di ogni fattoria (e l'admin del server) stipulano, modificano e annullano le polizze della propria fattoria. SÌ: lo fa solo l'admin del server - per i server in cui l'admin gestisce l'assicurazione.",
  "UIT: de beheerders van elke boerderij (en de serverbeheerder) sluiten, wijzigen en beëindigen de polissen van hun boerderij. AAN: alleen de serverbeheerder doet dat - voor servers waar de beheerder de verzekering regelt.")
t("tp_insurance_region", "Insurance region", "Versicherungsregion", "Région d'assurance", "Region ubezpieczenia",
  "Región del seguro", "Regione assicurativa", "Verzekeringsregio")
t("tp_tip_insurance_region",
  "Whose insurance rules and prices apply. Auto detects the country (and state or province) from the map.",
  "Wessen Versicherungsregeln und Preise gelten. Auto erkennt das Land (und Bundesland oder Provinz) anhand der Karte.",
  "Règles et prix d'assurance appliqués. Auto détecte le pays (et l'État ou la province) d'après la carte.",
  "Czyje zasady i ceny ubezpieczeń obowiązują. Auto rozpoznaje kraj (oraz stan lub prowincję) na podstawie mapy.",
  "Qué reglas y precios de seguro se aplican. Auto detecta el país (y el estado o la provincia) a partir del mapa.",
  "Quali regole e prezzi assicurativi si applicano. Auto rileva il paese (e lo stato o la provincia) dalla mappa.",
  "Welke verzekeringsregels en prijzen gelden. Auto herkent het land (en de staat of provincie) aan de kaart.")
t("tp_insurance_region_auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto")
t("tp_insurance_region_auto_found", "Auto (%s)", "Auto (%s)", "Auto (%s)", "Auto (%s)", "Auto (%s)", "Auto (%s)", "Auto (%s)")
t("finance_tornadoInsurancePremium", "Insurance premiums", "Versicherungsprämien", "Primes d'assurance",
  "Składki ubezpieczeniowe", "Primas de seguro", "Premi assicurativi", "Verzekeringspremies")
t("finance_tornadoInsurancePayout", "Insurance payouts", "Versicherungsleistungen", "Indemnités d'assurance",
  "Wypłaty z ubezpieczenia", "Indemnizaciones del seguro", "Risarcimenti assicurativi", "Verzekeringsuitkeringen")
t("tp_money_ins_premium", "Insurance premiums", "Versicherungsprämien", "Primes d'assurance", "Składki ubezpieczeniowe",
  "Primas de seguro", "Premi assicurativi", "Verzekeringspremies")
t("tp_money_ins_payout", "Insurance payouts", "Versicherungsleistungen", "Indemnités d'assurance", "Wypłaty z ubezpieczenia",
  "Indemnizaciones del seguro", "Risarcimenti assicurativi", "Verzekeringsuitkeringen")
t("tp_msg_ins_premium_charged", "Insurance: monthly premium of %s charged.",
  "Versicherung: Monatsprämie von %s abgebucht.",
  "Assurance : prime mensuelle de %s prélevée.",
  "Ubezpieczenie: pobrano miesięczną składkę %s.",
  "Seguro: cobrada la prima mensual de %s.",
  "Assicurazione: addebitato il premio mensile di %s.",
  "Verzekering: maandpremie van %s afgeschreven.")
t("tp_msg_ins_payout", "Insurance: %s paid out to your farm.",
  "Versicherung: %s an deinen Hof ausgezahlt.",
  "Assurance : %s versés à votre ferme.",
  "Ubezpieczenie: wypłacono %s na konto gospodarstwa.",
  "Seguro: %s pagados a tu granja.",
  "Assicurazione: %s versati alla tua fattoria.",
  "Verzekering: %s uitgekeerd aan je boerderij.")
t("tp_msg_ins_test_timer", "Insurance: test countdown finished.",
  "Versicherung: Test-Countdown abgelaufen.",
  "Assurance : compte à rebours de test terminé.",
  "Ubezpieczenie: testowe odliczanie zakończone.",
  "Seguro: cuenta atrás de prueba terminada.",
  "Assicurazione: conto alla rovescia di prova terminato.",
  "Verzekering: testaftelling afgelopen.")
t("tp_msg_damage_report", "%s: %d of your fields hit, about %.2f ha of crop lost (worst: field %d, %d %%).",
  "%s: %d deiner Felder getroffen, etwa %.2f ha Ernte verloren (am schlimmsten: Feld %d, %d %%).",
  "%s : %d de vos champs touchés, environ %.2f ha de récolte perdus (le plus touché : champ %d, %d %%).",
  "%s: trafione pola: %d, utracono ok. %.2f ha upraw (najgorzej: pole %d, %d %%).",
  "%s: %d de tus campos afectados, unas %.2f ha de cosecha perdidas (el peor: campo %d, %d %%).",
  "%s: %d dei tuoi campi colpiti, circa %.2f ha di raccolto perso (il peggiore: campo %d, %d %%).",
  "%s: %d van je velden geraakt, ongeveer %.2f ha oogst verloren (het ergst: veld %d, %d %%).")
t("tp_cause_tornado", "Tornado", "Tornado", "Tornade", "Tornado", "Tornado", "Tornado", "Tornado")
t("tp_cause_hail", "Hail", "Hagel", "Grêle", "Grad", "Granizo", "Grandine", "Hagel")
t("tp_cause_drought", "Drought", "Dürre", "Sécheresse", "Susza", "Sequía", "Siccità", "Droogte")
t("tp_cause_flood", "Flood", "Überschwemmung", "Inondation", "Powódź", "Inundación", "Alluvione", "Overstroming")
t("tp_cause_fire", "Field fire", "Feldbrand", "Feu de champ", "Pożar pola", "Incendio de campo", "Incendio", "Veldbrand")
# Crop insurance (phase 2a) - plans, interface, letters
t("tp_plan_none", "No crop insurance", "Keine Ernteversicherung", "Pas d'assurance récolte", "Brak ubezpieczenia upraw",
  "Sin seguro de cosecha", "Nessuna assicurazione raccolto", "Geen oogstverzekering")
t("tp_plan_RP", "Revenue Protection (RP)", "Ertragswertschutz (RP)", "Protection du revenu (RP)", "Ochrona przychodu (RP)",
  "Protección de ingresos (RP)", "Protezione del reddito (RP)", "Inkomensbescherming (RP)")
t("tp_plan_RPHPE", "Revenue Protection, no harvest price (RPHPE)", "Ertragswertschutz ohne Erntepreis (RPHPE)",
  "Protection du revenu sans prix de récolte (RPHPE)", "Ochrona przychodu bez ceny zbiorów (RPHPE)",
  "Protección de ingresos sin precio de cosecha (RPHPE)", "Protezione del reddito senza prezzo di raccolta (RPHPE)",
  "Inkomensbescherming zonder oogstprijs (RPHPE)")
t("tp_plan_YP", "Yield Protection (YP)", "Ertragsschutz (YP)", "Protection du rendement (YP)", "Ochrona plonu (YP)",
  "Protección del rendimiento (YP)", "Protezione della resa (YP)", "Opbrengstbescherming (YP)")
t("tp_plan_APH", "Yield cover, specialty crops (APH)", "Ertragsschutz Sonderkulturen (APH)", "Rendement, cultures spéciales (APH)",
  "Plon, uprawy specjalne (APH)", "Rendimiento, cultivos especiales (APH)", "Resa, colture speciali (APH)",
  "Opbrengst, bijzondere gewassen (APH)")
t("tp_plan_COST", "Production cost cover (COST)", "Produktionskostenschutz (COST)", "Coûts de production (COST)",
  "Koszty produkcji (COST)", "Costes de producción (COST)", "Costi di produzione (COST)", "Productiekosten (COST)")
t("tp_plan_FULL", "Full yield cover (FULL)", "Voller Ertragsschutz (FULL)", "Rendement complet (FULL)", "Pełny plon (FULL)",
  "Rendimiento completo (FULL)", "Resa completa (FULL)", "Volledige opbrengst (FULL)")
# Crop insurance phase 2b - cover options of the other countries, value setting, claim letters
t("tp_plan_HAIL", "Hail", "Hagel", "Grêle", "Grad", "Granizo", "Grandine", "Hagel")
t("tp_plan_HAIL_STORM", "Hail + storm + heavy rain", "Hagel + Sturm + Starkregen", "Grêle + tempête + fortes pluies",
  "Grad + huragan + ulewa", "Granizo + viento + lluvia intensa", "Grandine + vento + pioggia intensa",
  "Hagel + storm + hevige regen")
t("tp_plan_HAIL_PLUS", "Hail plus (wind, fire)", "Hagel plus (Sturm, Feuer)", "Grêle plus (vent, feu)", "Grad plus (wiatr, ogień)",
  "Granizo plus (viento, incendio)", "Grandine plus (vento, incendio)", "Hagel plus (wind, brand)")
t("tp_plan_HAIL_ONLY", "Hail only (no subsidy)", "Nur Hagel (ohne Zuschuss)", "Grêle seule (sans aide)", "Tylko grad (bez dopłaty)",
  "Solo granizo (sin subvención)", "Solo grandine (senza contributo)", "Alleen hagel (zonder subsidie)")
t("tp_plan_PACKAGE", "Multi-peril package", "Mehrgefahrenpaket", "Formule multirisque", "Pakiet wieloryzykowy",
  "Paquete multirriesgo", "Pacchetto multirischio", "Meerdere-risicopakket")
t("tp_plan_PACKAGE_WIND", "Multi-peril package + windstorm", "Mehrgefahrenpaket + Sturm", "Formule multirisque + tempête",
  "Pakiet wieloryzykowy + huragan", "Paquete multirriesgo + viento", "Pacchetto multirischio + vento",
  "Meerdere-risicopakket + storm")
t("tp_plan_NAMED", "Named perils", "Benannte Gefahren", "Risques nommés", "Wymienione ryzyka", "Riesgos nombrados",
  "Rischi nominati", "Benoemde risico's")
t("tp_plan_MULTI", "Multi-peril", "Mehrgefahren", "Multirisque", "Wieloryzykowe", "Multirriesgo", "Multirischio", "Meerdere risico's")
t("tp_plan_MRC", "Multi-risk policy", "Mehrgefahrenversicherung", "Assurance multirisque climatique", "Polisa wieloryzykowa",
  "Póliza multirriesgo", "Polizza multirischio", "Brede weersverzekering")
t("tp_plan_MOD1", "Module 1 - whole farm, disasters", "Modul 1 - ganzer Betrieb, Katastrophen", "Module 1 - toute l'exploitation, catastrophes",
  "Moduł 1 - całe gospodarstwo, katastrofy", "Módulo 1 - explotación, catastróficos", "Modulo 1 - intera azienda, catastrofi",
  "Module 1 - heel bedrijf, rampen")
t("tp_plan_MOD2", "Module 2 - all risks per field", "Modul 2 - alle Risiken je Feld", "Module 2 - tous risques par parcelle",
  "Moduł 2 - wszystkie ryzyka na pole", "Módulo 2 - todos los riesgos por parcela", "Modulo 2 - tutti i rischi per campo",
  "Module 2 - alle risico's per veld")
t("tp_plan_MODP", "Module P - named perils", "Modul P - benannte Gefahren", "Module P - risques nommés", "Moduł P - wymienione ryzyka",
  "Módulo P - riesgos nombrados", "Modulo P - rischi nominati", "Module P - benoemde risico's")
t("tp_plan_IT_A", "All-risk policy (type A)", "Allgefahren (Typ A)", "Tous risques (type A)", "Wszystkie ryzyka (typ A)",
  "Todo riesgo (tipo A)", "Tutti i rischi (tipo A)", "Alle risico's (type A)")
t("tp_plan_IT_B", "Disasters + weather (type B)", "Katastrophen + Wetter (Typ B)", "Catastrophes + météo (type B)",
  "Katastrofy + pogoda (typ B)", "Catastróficos + clima (tipo B)", "Catastrofali + frequenza (tipo B)", "Rampen + weer (type B)")
t("tp_plan_IT_C", "Weather perils (type C)", "Wettergefahren (Typ C)", "Risques météo (type C)", "Ryzyka pogodowe (typ C)",
  "Riesgos climáticos (tipo C)", "Rischi di frequenza (tipo C)", "Weerrisico's (type C)")
t("tp_plan_IT_C2", "Hail + wind (type C)", "Hagel + Sturm (Typ C)", "Grêle + vent (type C)", "Grad + wiatr (typ C)",
  "Granizo + viento (tipo C)", "Grandine + vento (tipo C)", "Hagel + wind (type C)")
t("tp_plan_IT_D", "Disasters only (type D)", "Nur Katastrophen (Typ D)", "Catastrophes seules (type D)", "Tylko katastrofy (typ D)",
  "Solo catastróficos (tipo D)", "Solo catastrofali (tipo D)", "Alleen rampen (type D)")
t("tp_plan_IT_F", "Simplified policy (SMART)", "Vereinfachte Police (SMART)", "Contrat simplifié (SMART)", "Polisa uproszczona (SMART)",
  "Póliza simplificada (SMART)", "Polizza semplificata (SMART)", "Vereenvoudigde polis (SMART)")
t("tp_plan_STATE", "State rice scheme", "Staatliches Reisprogramm", "Programme public riz", "Państwowy program ryżowy",
  "Programa estatal de arroz", "Programma statale per il riso", "Overheidsregeling rijst")
t("tp_insurance_value", "Sum insured", "Versicherungssumme", "Capital assuré", "Suma ubezpieczenia", "Suma asegurada",
  "Somma assicurata", "Verzekerde som")
t("tp_tip_insurance_value",
  "Game values: the field's harvest at the map's prices. Real-world values: the country's own sums per hectare from the insurance data, converted to game money (euros, approximate rates). The US, Canada and Brazil always use game values.",
  "Spielwerte: die Ernte des Feldes zu den Preisen der Karte. Reale Werte: die Summen pro Hektar des Landes aus den Versicherungsdaten, in Spielgeld umgerechnet (Euro, ungefähre Kurse). USA, Kanada und Brasilien nutzen immer Spielwerte.",
  "Valeurs du jeu : la récolte du champ aux prix de la carte. Valeurs réelles : les sommes par hectare du pays issues des données d'assurance, converties en argent du jeu (euros, taux approximatifs). Les États-Unis, le Canada et le Brésil utilisent toujours les valeurs du jeu.",
  "Wartości z gry: plon pola po cenach z mapy. Wartości rzeczywiste: kwoty na hektar danego kraju z danych ubezpieczeniowych, przeliczone na pieniądze w grze (euro, kursy przybliżone). USA, Kanada i Brazylia zawsze używają wartości z gry.",
  "Valores del juego: la cosecha del campo a los precios del mapa. Valores reales: las sumas por hectárea del país según los datos del seguro, convertidas a dinero del juego (euros, tipos aproximados). EE. UU., Canadá y Brasil usan siempre valores del juego.",
  "Valori di gioco: il raccolto del campo ai prezzi della mappa. Valori reali: le somme per ettaro del paese dai dati assicurativi, convertite in denaro di gioco (euro, cambi approssimativi). Stati Uniti, Canada e Brasile usano sempre i valori di gioco.",
  "Spelwaarden: de oogst van het veld tegen de prijzen van de kaart. Echte waarden: de bedragen per hectare van het land uit de verzekeringsgegevens, omgerekend naar speelgeld (euro, benaderde koersen). De VS, Canada en Brazilië gebruiken altijd spelwaarden.")
t("tp_insurance_value_game", "Game values", "Spielwerte", "Valeurs du jeu", "Wartości z gry", "Valores del juego", "Valori di gioco", "Spelwaarden")
t("tp_insurance_value_real", "Real-world values", "Reale Werte", "Valeurs réelles", "Wartości rzeczywiste", "Valores reales",
  "Valori reali", "Echte waarden")
t("tp_msg_ins_claim_not_covered", "Claim for field %d closed: your policy does not cover %s.",
  "Schadensfall Feld %d geschlossen: Deine Police deckt %s nicht ab.",
  "Sinistre du champ %d clos : votre contrat ne couvre pas : %s.",
  "Szkoda na polu %d zamknięta: twoja polisa nie obejmuje: %s.",
  "Siniestro del campo %d cerrado: tu póliza no cubre: %s.",
  "Sinistro del campo %d chiuso: la tua polizza non copre: %s.",
  "Schade veld %d gesloten: je polis dekt dit niet: %s.")
t("tp_msg_ins_claim_threshold", "Claim for field %d: %d %% lost is below the scheme's %d %% damage threshold - no payout yet.",
  "Schadensfall Feld %d: %d %% Verlust liegen unter der Schadensschwelle von %d %% - noch keine Auszahlung.",
  "Sinistre du champ %d : %d %% perdus restent sous le seuil de %d %% du programme - pas encore d'indemnité.",
  "Szkoda na polu %d: strata %d %% jest poniżej progu %d %% programu - na razie brak wypłaty.",
  "Siniestro del campo %d: el %d %% perdido está por debajo del umbral del %d %% - aún sin pago.",
  "Sinistro del campo %d: il %d %% perso è sotto la soglia del %d %% - ancora nessun pagamento.",
  "Schade veld %d: %d %% verlies ligt onder de schadedrempel van %d %% - nog geen uitkering.")
t("tp_insurance_crop_plan", "Crop insurance (your farm)", "Ernteversicherung (dein Hof)", "Assurance récolte (votre ferme)",
  "Ubezpieczenie upraw (twoje gospodarstwo)", "Seguro de cosecha (tu granja)", "Assicurazione raccolto (la tua fattoria)",
  "Oogstverzekering (je boerderij)")
t("tp_tip_insurance_crop_plan",
  "Insures every field your farm owns with an insurable crop against tornado, hail, drought, flood and fire losses. Yield plans pay at the price locked for the policy year; Revenue Protection pays at the higher of the locked and the current price. Cover starts about a week (real-life time) after buying.",
  "Versichert jedes Feld deines Hofs mit einer versicherbaren Kultur gegen Schäden durch Tornado, Hagel, Dürre, Überschwemmung und Feuer. Ertragspläne zahlen zum für das Versicherungsjahr festgelegten Preis; der Ertragswertschutz zahlt zum höheren aus festgelegtem und aktuellem Preis. Der Schutz beginnt etwa eine Woche (reale Zeit) nach dem Kauf.",
  "Assure chaque champ de votre ferme portant une culture assurable contre les pertes dues aux tornades, à la grêle, à la sécheresse, aux inondations et au feu. Les plans de rendement paient au prix fixé pour l'année du contrat ; la protection du revenu paie au plus élevé du prix fixé et du prix actuel. La couverture commence environ une semaine (temps réel) après l'achat.",
  "Ubezpiecza każde pole twojego gospodarstwa z uprawą podlegającą ubezpieczeniu od strat po tornadzie, gradzie, suszy, powodzi i pożarze. Plany plonu wypłacają według ceny ustalonej na rok polisy; ochrona przychodu według wyższej z cen ustalonej i bieżącej. Ochrona zaczyna się ok. tydzień (czasu rzeczywistego) po zakupie.",
  "Asegura cada campo de tu granja con un cultivo asegurable contra pérdidas por tornado, granizo, sequía, inundación e incendio. Los planes de rendimiento pagan al precio fijado para el año de la póliza; la protección de ingresos paga al mayor entre el precio fijado y el actual. La cobertura empieza una semana (tiempo real) después de la compra.",
  "Assicura ogni campo della tua fattoria con una coltura assicurabile contro le perdite da tornado, grandine, siccità, alluvione e incendio. I piani di resa pagano al prezzo fissato per l'anno di polizza; la protezione del reddito paga al maggiore tra il prezzo fissato e quello attuale. La copertura inizia circa una settimana (tempo reale) dopo l'acquisto.",
  "Verzekert elk veld van je boerderij met een verzekerbaar gewas tegen verliezen door tornado, hagel, droogte, overstroming en brand. Opbrengstplannen betalen tegen de prijs die voor het polisjaar is vastgelegd; inkomensbescherming betaalt tegen de hoogste van de vastgelegde en de huidige prijs. De dekking begint ongeveer een week (echte tijd) na aankoop.")
t("tp_insurance_crop_coverage", "Coverage level", "Deckungsgrad", "Niveau de couverture", "Poziom ochrony", "Nivel de cobertura",
  "Livello di copertura", "Dekkingsniveau")
t("tp_tip_insurance_crop_coverage",
  "Share of the expected harvest value that is insured. Losses up to the rest (e.g. 25 % at 75 % coverage) are yours; higher coverage costs more. Crops that are unusual for the region are capped at 70 % and cost 25 % more.",
  "Anteil des erwarteten Erntewerts, der versichert ist. Verluste bis zum Rest (z. B. 25 % bei 75 % Deckung) trägst du selbst; höhere Deckung kostet mehr. Für die Region ungewöhnliche Kulturen sind auf 70 % begrenzt und kosten 25 % mehr.",
  "Part de la valeur de récolte attendue qui est assurée. Les pertes jusqu'au reste (p. ex. 25 % avec une couverture à 75 %) sont à votre charge ; une couverture plus élevée coûte plus. Les cultures inhabituelles pour la région sont limitées à 70 %, avec un surcoût de 25 %.",
  "Część oczekiwanej wartości zbiorów, która jest ubezpieczona. Straty do pozostałej części (np. 25 % przy 75 % ochrony) ponosisz sam; wyższa ochrona kosztuje więcej. Uprawy nietypowe dla regionu: maksymalnie 70 %, a cena wyższa o 25 %.",
  "Parte del valor esperado de la cosecha que está asegurada. Las pérdidas hasta el resto (p. ej., 25 % con una cobertura del 75 %) corren de tu cuenta; más cobertura cuesta más. Los cultivos poco habituales en la región tienen un máximo del 70 % y cuestan un 25 % más.",
  "Quota del valore atteso del raccolto che è assicurata. Le perdite fino al resto (ad es. 25 % con copertura al 75 %) sono a tuo carico; una copertura maggiore costa di più. Le colture insolite per la regione sono limitate al 70 %, con un sovrapprezzo del 25 %.",
  "Deel van de verwachte oogstwaarde dat verzekerd is. Verliezen tot het restant (bijv. 25 % bij een dekking van 75 %) zijn voor jou; meer dekking kost meer. Voor de regio ongebruikelijke gewassen: maximaal 70 %, en 25 % meer premie.")
t("tp_insurance_coverage_option", "%d %% (about %s / month)", "%d %% (etwa %s / Monat)", "%d %% (environ %s / mois)",
  "%d %% (ok. %s / mies.)", "%d %% (unos %s / mes)", "%d %% (circa %s / mese)", "%d %% (ongeveer %s / maand)")
t("tp_insurance_sales", "Sales closing date", "Antragsschluss", "Date limite de souscription", "Termin zawarcia umów",
  "Fecha límite de contratación", "Termine di sottoscrizione", "Sluitingsdatum")
t("tp_tip_insurance_sales",
  "Crop policies can only be bought or changed in late winter and early spring, like real insurance before planting. Auto: only with seasonal growth (off when crops grow all year).",
  "Ernteversicherungen können nur im Spätwinter und Frühlingsanfang abgeschlossen oder geändert werden, wie echte Versicherungen vor der Aussaat. Auto: nur mit saisonalem Wachstum (aus, wenn Pflanzen ganzjährig wachsen).",
  "Les contrats récolte ne peuvent être souscrits ou modifiés qu'en fin d'hiver et début de printemps, comme une vraie assurance avant les semis. Auto : seulement avec la croissance saisonnière (désactivé si les cultures poussent toute l'année).",
  "Polisy upraw można kupić lub zmienić tylko późną zimą i wczesną wiosną, jak prawdziwe ubezpieczenie przed siewem. Auto: tylko przy sezonowym wzroście (wyłączone, gdy uprawy rosną cały rok).",
  "Las pólizas de cosecha solo se pueden contratar o cambiar a finales de invierno y principios de primavera, como un seguro real antes de la siembra. Auto: solo con crecimiento estacional (desactivado si los cultivos crecen todo el año).",
  "Le polizze raccolto si possono stipulare o modificare solo a fine inverno e inizio primavera, come una vera assicurazione prima della semina. Auto: solo con crescita stagionale (disattivato se le colture crescono tutto l'anno).",
  "Oogstpolissen kunnen alleen eind winter en begin lente worden afgesloten of gewijzigd, zoals een echte verzekering vóór het zaaien. Auto: alleen bij seizoensgroei (uit als gewassen het hele jaar groeien).")
t("tp_insurance_sales_auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto", "Auto")
t("tp_insurance_sales_on", "Always", "Immer", "Toujours", "Zawsze", "Siempre", "Sempre", "Altijd")
t("tp_insurance_sales_off", "Never (buy any time)", "Nie (jederzeit kaufen)", "Jamais (achat à tout moment)",
  "Nigdy (kupno w każdej chwili)", "Nunca (comprar en cualquier momento)", "Mai (acquisto in qualsiasi momento)",
  "Nooit (altijd kopen)")
t("tp_insurance_crop_status", "Crop policy status", "Status der Ernteversicherung", "État du contrat récolte",
  "Stan polisy upraw", "Estado de la póliza de cosecha", "Stato della polizza raccolto", "Status van de oogstpolis")
t("tp_btn_show", "Show", "Anzeigen", "Afficher", "Pokaż", "Mostrar", "Mostra", "Tonen")
t("tp_msg_ins_crop_status", "Crop insurance: %s, %d %% (%s) - %d fields, insured value %s, about %s per month, %d open claims.",
  "Ernteversicherung: %s, %d %% (%s) - %d Felder, Versicherungswert %s, etwa %s pro Monat, %d offene Schadensfälle.",
  "Assurance récolte : %s, %d %% (%s) - %d champs, valeur assurée %s, environ %s par mois, %d sinistres en cours.",
  "Ubezpieczenie upraw: %s, %d %% (%s) - pola: %d, suma ubezpieczenia %s, ok. %s miesięcznie, otwarte szkody: %d.",
  "Seguro de cosecha: %s, %d %% (%s) - %d campos, valor asegurado %s, unos %s al mes, %d siniestros abiertos.",
  "Assicurazione raccolto: %s, %d %% (%s) - %d campi, valore assicurato %s, circa %s al mese, %d sinistri aperti.",
  "Oogstverzekering: %s, %d %% (%s) - %d velden, verzekerde waarde %s, ongeveer %s per maand, %d open schadegevallen.")
t("tp_ins_status_pending", "starting soon", "beginnt bald", "commence bientôt", "wkrótce aktywna", "empieza pronto",
  "inizia a breve", "begint binnenkort")
t("tp_ins_status_active", "active", "aktiv", "active", "aktywna", "activa", "attiva", "actief")
t("tp_msg_ins_crop_none_status", "Crop insurance: your farm has no crop policy.", "Ernteversicherung: Dein Hof hat keine Police.",
  "Assurance récolte : votre ferme n'a pas de contrat.", "Ubezpieczenie upraw: twoje gospodarstwo nie ma polisy.",
  "Seguro de cosecha: tu granja no tiene póliza.", "Assicurazione raccolto: la tua fattoria non ha una polizza.",
  "Oogstverzekering: je boerderij heeft geen polis.")
t("tp_msg_ins_crop_bought", "Crop insurance %s at %d %% confirmed (about %s per month). Cover starts in %d d %d h.",
  "Ernteversicherung %s mit %d %% bestätigt (etwa %s pro Monat). Der Schutz beginnt in %d T %d Std.",
  "Assurance récolte %s à %d %% confirmée (environ %s par mois). La couverture commence dans %d j %d h.",
  "Ubezpieczenie upraw %s na %d %% potwierdzone (ok. %s miesięcznie). Ochrona zaczyna się za %d d %d godz.",
  "Seguro de cosecha %s al %d %% confirmado (unos %s al mes). La cobertura empieza en %d d %d h.",
  "Assicurazione raccolto %s al %d %% confermata (circa %s al mese). La copertura inizia tra %d g %d h.",
  "Oogstverzekering %s met %d %% bevestigd (ongeveer %s per maand). De dekking begint over %d d %d u.")
t("tp_msg_ins_crop_changed", "Crop insurance changed to %s at %d %% (about %s per month).",
  "Ernteversicherung geändert auf %s mit %d %% (etwa %s pro Monat).",
  "Assurance récolte modifiée : %s à %d %% (environ %s par mois).",
  "Ubezpieczenie upraw zmienione na %s, %d %% (ok. %s miesięcznie).",
  "Seguro de cosecha cambiado a %s al %d %% (unos %s al mes).",
  "Assicurazione raccolto modificata in %s al %d %% (circa %s al mese).",
  "Oogstverzekering gewijzigd naar %s met %d %% (ongeveer %s per maand).")
t("tp_msg_ins_crop_active", "Your crop insurance (%s, %d %%) is now active.", "Deine Ernteversicherung (%s, %d %%) ist jetzt aktiv.",
  "Votre assurance récolte (%s, %d %%) est maintenant active.", "Twoje ubezpieczenie upraw (%s, %d %%) jest teraz aktywne.",
  "Tu seguro de cosecha (%s, %d %%) ya está activo.", "La tua assicurazione raccolto (%s, %d %%) è ora attiva.",
  "Je oogstverzekering (%s, %d %%) is nu actief.")
t("tp_msg_ins_crop_cancelled", "Crop insurance cancelled. Open claims are still settled.",
  "Ernteversicherung gekündigt. Offene Schadensfälle werden noch abgewickelt.",
  "Assurance récolte résiliée. Les sinistres en cours sont encore réglés.",
  "Ubezpieczenie upraw anulowane. Otwarte szkody zostaną jeszcze rozliczone.",
  "Seguro de cosecha cancelado. Los siniestros abiertos se siguen liquidando.",
  "Assicurazione raccolto annullata. I sinistri aperti vengono comunque liquidati.",
  "Oogstverzekering opgezegd. Open schadegevallen worden nog afgehandeld.")
t("tp_msg_ins_crop_renewed", "New policy year: your crop insurance prices are locked again.",
  "Neues Versicherungsjahr: Die Preise deiner Ernteversicherung werden neu festgelegt.",
  "Nouvelle année de contrat : les prix de votre assurance récolte sont fixés à nouveau.",
  "Nowy rok polisy: ceny w twoim ubezpieczeniu upraw zostaną ustalone na nowo.",
  "Nuevo año de póliza: los precios de tu seguro de cosecha se fijan de nuevo.",
  "Nuovo anno di polizza: i prezzi della tua assicurazione raccolto vengono fissati di nuovo.",
  "Nieuw polisjaar: de prijzen van je oogstverzekering worden opnieuw vastgelegd.")
t("tp_msg_ins_crop_none", "Your farm has no crop insurance to cancel.", "Dein Hof hat keine Ernteversicherung zum Kündigen.",
  "Votre ferme n'a pas d'assurance récolte à résilier.", "Twoje gospodarstwo nie ma ubezpieczenia upraw do anulowania.",
  "Tu granja no tiene seguro de cosecha que cancelar.", "La tua fattoria non ha un'assicurazione raccolto da annullare.",
  "Je boerderij heeft geen oogstverzekering om op te zeggen.")
t("tp_msg_ins_crop_unavailable", "Crop insurance for this region comes in a later update.",
  "Die Ernteversicherung für diese Region kommt in einem späteren Update.",
  "L'assurance récolte pour cette région arrive dans une prochaine mise à jour.",
  "Ubezpieczenie upraw dla tego regionu pojawi się w kolejnej aktualizacji.",
  "El seguro de cosecha para esta región llegará en una próxima actualización.",
  "L'assicurazione raccolto per questa regione arriverà in un prossimo aggiornamento.",
  "Oogstverzekering voor deze regio komt in een volgende update.")
t("tp_msg_ins_crop_unknown_plan", "This crop insurance plan is not offered in this region.",
  "Dieser Versicherungsplan wird in dieser Region nicht angeboten.",
  "Ce plan d'assurance récolte n'est pas proposé dans cette région.",
  "Ten plan ubezpieczenia upraw nie jest dostępny w tym regionie.",
  "Este plan de seguro de cosecha no se ofrece en esta región.",
  "Questo piano assicurativo non è offerto in questa regione.",
  "Dit verzekeringsplan wordt in deze regio niet aangeboden.")
t("tp_msg_ins_crop_sales_closed", "Crop insurance can only be bought or changed in late winter and early spring.",
  "Ernteversicherungen können nur im Spätwinter und Frühlingsanfang abgeschlossen oder geändert werden.",
  "L'assurance récolte ne peut être souscrite ou modifiée qu'en fin d'hiver et début de printemps.",
  "Ubezpieczenie upraw można kupić lub zmienić tylko późną zimą i wczesną wiosną.",
  "El seguro de cosecha solo se puede contratar o cambiar a finales de invierno y principios de primavera.",
  "L'assicurazione raccolto si può stipulare o modificare solo a fine inverno e inizio primavera.",
  "Oogstverzekering kan alleen eind winter en begin lente worden afgesloten of gewijzigd.")
t("tp_msg_ins_crop_storm", "No new cover while a tornado or a storm outbreak is under way.",
  "Kein neuer Versicherungsschutz, solange ein Tornado oder eine Unwetterserie im Gang ist.",
  "Pas de nouvelle couverture pendant une tornade ou une série d'orages.",
  "Brak nowej ochrony w trakcie tornada lub serii burz.",
  "No se contrata cobertura nueva durante un tornado o una serie de tormentas.",
  "Nessuna nuova copertura durante un tornado o una serie di temporali.",
  "Geen nieuwe dekking zolang er een tornado of een reeks stormen bezig is.")
t("tp_msg_ins_claim_received", "Insurance claim for field %d (%s, about %d %% lost) received - an adjuster will visit.",
  "Schadensmeldung für Feld %d (%s, etwa %d %% verloren) erhalten - ein Gutachter kommt vorbei.",
  "Déclaration de sinistre pour le champ %d (%s, environ %d %% perdus) reçue - un expert va passer.",
  "Zgłoszenie szkody dla pola %d (%s, ok. %d %% strat) przyjęte - przyjedzie rzeczoznawca.",
  "Siniestro del campo %d (%s, alrededor del %d %% perdido) recibido - vendrá un perito.",
  "Denuncia di sinistro per il campo %d (%s, circa %d %% perso) ricevuta - passerà un perito.",
  "Schademelding voor veld %d (%s, ongeveer %d %% verloren) ontvangen - er komt een expert langs.")
t("tp_msg_ins_claim_inspected", "The adjuster has inspected field %d. A decision follows soon.",
  "Der Gutachter hat Feld %d besichtigt. Die Entscheidung folgt bald.",
  "L'expert a inspecté le champ %d. La décision suit bientôt.",
  "Rzeczoznawca obejrzał pole %d. Decyzja wkrótce.",
  "El perito ha inspeccionado el campo %d. La decisión llegará pronto.",
  "Il perito ha ispezionato il campo %d. La decisione arriverà a breve.",
  "De expert heeft veld %d bekeken. De beslissing volgt binnenkort.")
t("tp_msg_ins_claim_approved", "Claim for field %d approved: %s will be paid.",
  "Schadensfall für Feld %d anerkannt: %s werden ausgezahlt.",
  "Sinistre du champ %d accepté : %s seront versés.",
  "Szkoda na polu %d uznana: zostanie wypłacone %s.",
  "Siniestro del campo %d aprobado: se pagarán %s.",
  "Sinistro del campo %d approvato: verranno pagati %s.",
  "Schade voor veld %d goedgekeurd: %s wordt uitbetaald.")
t("tp_msg_ins_claim_paid", "Insurance paid for field %d: %s.", "Versicherungsleistung für Feld %d: %s.",
  "Indemnité versée pour le champ %d : %s.", "Wypłata ubezpieczenia za pole %d: %s.",
  "Indemnización pagada por el campo %d: %s.", "Risarcimento pagato per il campo %d: %s.",
  "Uitkering voor veld %d: %s.")
t("tp_msg_ins_claim_deductible", "Claim for field %d: %d %% lost this year is within your uninsured part (%d %% coverage) - no payout yet.",
  "Schadensfall Feld %d: %d %% Verlust in diesem Jahr liegen in deinem unversicherten Teil (%d %% Deckung) - noch keine Auszahlung.",
  "Sinistre du champ %d : %d %% perdus cette année restent dans votre part non assurée (couverture %d %%) - pas encore d'indemnité.",
  "Szkoda na polu %d: %d %% strat w tym roku mieści się w nieubezpieczonej części (ochrona %d %%) - na razie brak wypłaty.",
  "Siniestro del campo %d: el %d %% perdido este año está dentro de tu parte no asegurada (cobertura %d %%) - aún sin pago.",
  "Sinistro del campo %d: il %d %% perso quest'anno rientra nella tua parte non assicurata (copertura %d %%) - ancora nessun pagamento.",
  "Schade veld %d: %d %% verlies dit jaar valt binnen je onverzekerde deel (%d %% dekking) - nog geen uitkering.")
t("tp_msg_ins_claim_no_policy", "Claim for field %d closed: there is no crop policy any more.",
  "Schadensfall Feld %d geschlossen: Es gibt keine Ernteversicherung mehr.",
  "Sinistre du champ %d clos : il n'y a plus de contrat récolte.",
  "Szkoda na polu %d zamknięta: nie ma już polisy upraw.",
  "Siniestro del campo %d cerrado: ya no hay póliza de cosecha.",
  "Sinistro del campo %d chiuso: non esiste più una polizza raccolto.",
  "Schade veld %d gesloten: er is geen oogstpolis meer.")
t("tp_msg_ins_claim_no_crop", "Claim for field %d closed: the crop is not insurable.",
  "Schadensfall Feld %d geschlossen: Die Kultur ist nicht versicherbar.",
  "Sinistre du champ %d clos : la culture n'est pas assurable.",
  "Szkoda na polu %d zamknięta: uprawa nie podlega ubezpieczeniu.",
  "Siniestro del campo %d cerrado: el cultivo no es asegurable.",
  "Sinistro del campo %d chiuso: la coltura non è assicurabile.",
  "Schade veld %d gesloten: het gewas is niet verzekerbaar.")
t("tp_msg_ins_off", "Insurance is turned off on this server.",
  "Die Versicherung ist auf diesem Server ausgeschaltet.",
  "L'assurance est désactivée sur ce serveur.",
  "Ubezpieczenia są wyłączone na tym serwerze.",
  "Los seguros están desactivados en este servidor.",
  "L'assicurazione è disattivata su questo server.",
  "Verzekering staat uit op deze server.")
t("tp_msg_ins_denied", "Insurance: only a farm manager or the server admin can change this farm's policies.",
  "Versicherung: Nur ein Hofverwalter oder der Server-Admin kann die Policen dieses Hofs ändern.",
  "Assurance : seul un gérant de la ferme ou l'admin du serveur peut modifier les contrats de cette ferme.",
  "Ubezpieczenie: tylko zarządca gospodarstwa lub admin serwera może zmieniać polisy tego gospodarstwa.",
  "Seguro: solo un gestor de la granja o el admin del servidor puede cambiar las pólizas de esta granja.",
  "Assicurazione: solo un gestore della fattoria o l'admin del server può modificare le polizze di questa fattoria.",
  "Verzekering: alleen een beheerder van de boerderij of de serverbeheerder kan de polissen van deze boerderij wijzigen.")
t("tp_msg_ins_denied_admin", "Insurance: on this server only the admin manages policies.",
  "Versicherung: Auf diesem Server verwaltet nur der Admin die Policen.",
  "Assurance : sur ce serveur, seul l'admin gère les contrats.",
  "Ubezpieczenie: na tym serwerze polisami zarządza tylko admin.",
  "Seguro: en este servidor solo el admin gestiona las pólizas.",
  "Assicurazione: su questo server solo l'admin gestisce le polizze.",
  "Verzekering: op deze server beheert alleen de admin de polissen.")
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
t("tp_msg_tow_bill", "EMERGENCY TOW: billed %s (tow %s, %d broken parts, new price %s)",
  "NOTFALL-ABSCHLEPPDIENST: %s berechnet (Abschleppen %s, %d kaputte Teile, Neupreis %s)",
  "REMORQUAGE D'URGENCE : %s facturés (remorquage %s, %d pièces cassées, prix neuf %s)",
  "HOLOWANIE AWARYJNE: naliczono %s (holowanie %s, %d zniszczonych części, cena nowego %s)",
  "REMOLQUE DE EMERGENCIA: facturado %s (remolque %s, %d piezas rotas, precio nuevo %s)",
  "TRAINO DI EMERGENZA: addebitati %s (traino %s, %d pezzi rotti, prezzo da nuovo %s)",
  "NOODSLEEPDIENST: %s in rekening gebracht (slepen %s, %d kapotte onderdelen, nieuwprijs %s)")
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

# =====================================================================================================
# INSURANCE - EQUIPMENT (phase 3)
# =====================================================================================================
t("tp_insurance_replacement", "Equipment: replacement value", "Geräte: Wiederbeschaffungswert", "Matériel : valeur de remplacement",
  "Sprzęt: wartość odtworzeniowa", "Equipos: valor de reposición", "Mezzi: valore di rimpiazzo", "Materieel: vervangingswaarde")
t("tp_tip_insurance_replacement",
  "Off: equipment claims are paid on the vehicle's sell price. On: on the dealer's replacement value, 15 percent more - closer to what buying the same vehicle again costs.",
  "Aus: Geräteschäden werden zum Verkaufspreis des Fahrzeugs bezahlt. An: zum Wiederbeschaffungswert beim Händler, 15 Prozent mehr - näher an dem, was der Neukauf desselben Fahrzeugs kostet.",
  "Désactivé : les sinistres matériel sont payés au prix de vente du véhicule. Activé : à la valeur de remplacement du concessionnaire, 15 pour cent de plus - plus proche du prix pour racheter le même véhicule.",
  "Wył.: szkody sprzętu są wypłacane według ceny sprzedaży pojazdu. Wł.: według wartości odtworzeniowej u dealera, o 15 procent więcej - bliżej kosztu ponownego zakupu tego samego pojazdu.",
  "Desactivado: los siniestros de equipos se pagan al precio de venta del vehículo. Activado: al valor de reposición del concesionario, un 15 por ciento más - más cerca de lo que cuesta volver a comprar el mismo vehículo.",
  "Disattivato: i sinistri dei mezzi sono pagati al prezzo di vendita del veicolo. Attivato: al valore di rimpiazzo del concessionario, il 15 per cento in più - più vicino al costo per ricomprare lo stesso veicolo.",
  "Uit: schades aan materieel worden betaald tegen de verkoopprijs van het voertuig. Aan: tegen de vervangingswaarde bij de dealer, 15 procent meer - dichter bij wat hetzelfde voertuig opnieuw kopen kost.")
t("tp_insurance_remove_totaled", "Equipment: remove total losses", "Geräte: Totalschäden entfernen", "Matériel : retirer les épaves",
  "Sprzęt: usuwaj szkody całkowite", "Equipos: retirar siniestros totales", "Mezzi: rimuovi i danni totali", "Materieel: total loss verwijderen")
t("tp_tip_insurance_remove_totaled",
  "On: accepting a total loss pays the insured value and the insurer collects the wreck (the vehicle is removed). Off: nothing is ever removed - accepting works like a buy-back (salvage value kept back, Salvage title).",
  "An: Wer einen Totalschaden annimmt, erhält den versicherten Wert und die Versicherung holt das Wrack ab (das Fahrzeug wird entfernt). Aus: Es wird nie etwas entfernt - Annehmen wirkt wie ein Rückkauf (Restwert wird abgezogen, Bergungstitel).",
  "Activé : accepter une perte totale paie la valeur assurée et l'assureur récupère l'épave (le véhicule est retiré). Désactivé : rien n'est jamais retiré - accepter fonctionne comme un rachat (valeur d'épave retenue, titre Épave).",
  "Wł.: przyjęcie szkody całkowitej wypłaca wartość ubezpieczenia, a ubezpieczyciel zabiera wrak (pojazd zostaje usunięty). Wył.: nic nie jest usuwane - przyjęcie działa jak odkup (wartość wraku potrącona, tytuł Wrak).",
  "Activado: aceptar un siniestro total paga el valor asegurado y la aseguradora retira el vehículo siniestrado (se elimina). Desactivado: nunca se elimina nada - aceptar funciona como una recompra (se descuenta el valor de restos, título de Siniestro).",
  "Attivato: accettare un danno totale paga il valore assicurato e l'assicuratore ritira il relitto (il veicolo viene rimosso). Disattivato: non viene mai rimosso nulla - accettare funziona come un riacquisto (valore di recupero trattenuto, titolo Relitto).",
  "Aan: wie een total loss accepteert, krijgt de verzekerde waarde en de verzekeraar haalt het wrak op (het voertuig verdwijnt). Uit: er verdwijnt nooit iets - accepteren werkt als terugkopen (restwaarde ingehouden, titel Wrak).")
t("tp_insurance_salvage", "Salvage title: sell price", "Bergungstitel: Verkaufspreis", "Titre Épave : prix de vente",
  "Tytuł Wrak: cena sprzedaży", "Título Siniestro: precio de venta", "Titolo Relitto: prezzo di vendita", "Titel Wrak: verkoopprijs")
t("tp_tip_insurance_salvage",
  "How much lower the sell price of a vehicle is that you bought back after a total loss, until it is repaired. Real salvage vehicles sell for about half.",
  "Um wie viel der Verkaufspreis eines nach einem Totalschaden zurückgekauften Fahrzeugs sinkt, bis es repariert ist. Echte Unfallfahrzeuge erzielen etwa die Hälfte.",
  "De combien baisse le prix de vente d'un véhicule racheté après une perte totale, jusqu'à sa réparation. Les vraies épaves se vendent environ à moitié prix.",
  "O ile niższa jest cena sprzedaży pojazdu odkupionego po szkodzie całkowitej, dopóki nie zostanie naprawiony. Prawdziwe wraki sprzedają się za około połowę.",
  "Cuánto baja el precio de venta de un vehículo recomprado tras un siniestro total, hasta que se repara. Los vehículos siniestrados reales se venden por la mitad aproximadamente.",
  "Di quanto si abbassa il prezzo di vendita di un veicolo riacquistato dopo un danno totale, finché non viene riparato. I veri relitti si vendono a circa metà prezzo.",
  "Hoeveel lager de verkoopprijs is van een voertuig dat je na een total loss hebt teruggekocht, tot het gerepareerd is. Echte wrakken gaan voor ongeveer de helft weg.")
t("tp_insurance_rebuilt", "Rebuilt title: sell price", "Wiederaufbau-Titel: Verkaufspreis", "Titre Reconstruit : prix de vente",
  "Tytuł Odbudowany: cena sprzedaży", "Título Reconstruido: precio de venta", "Titolo Ricostruito: prezzo di vendita",
  "Titel Herbouwd: verkoopprijs")
t("tp_tip_insurance_rebuilt",
  "A bought-back vehicle that has been repaired keeps a Rebuilt title for good: its sell price stays this much lower. Real rebuilt vehicles sell for 20 to 40 percent less.",
  "Ein zurückgekauftes Fahrzeug, das repariert wurde, behält für immer einen Wiederaufbau-Titel: Sein Verkaufspreis bleibt um so viel niedriger. Echte wiederaufgebaute Fahrzeuge erzielen 20 bis 40 Prozent weniger.",
  "Un véhicule racheté puis réparé garde pour toujours un titre Reconstruit : son prix de vente reste plus bas d'autant. Les vrais véhicules reconstruits se vendent 20 à 40 pour cent moins cher.",
  "Odkupiony i naprawiony pojazd zachowuje na zawsze tytuł Odbudowany: jego cena sprzedaży pozostaje o tyle niższa. Prawdziwe odbudowane pojazdy sprzedają się o 20 do 40 procent taniej.",
  "Un vehículo recomprado y ya reparado conserva para siempre un título de Reconstruido: su precio de venta sigue siendo así de bajo. Los vehículos reconstruidos reales se venden entre un 20 y un 40 por ciento más baratos.",
  "Un veicolo riacquistato e riparato mantiene per sempre un titolo Ricostruito: il suo prezzo di vendita resta più basso di tanto. I veri veicoli ricostruiti si vendono dal 20 al 40 per cento in meno.",
  "Een teruggekocht voertuig dat gerepareerd is, houdt voorgoed de titel Herbouwd: de verkoopprijs blijft zoveel lager. Echte herbouwde voertuigen gaan voor 20 tot 40 procent minder weg.")
t("tp_insurance_title_penalty_option", "-%d %%", "-%d %%", "-%d %%", "-%d %%", "-%d %%", "-%d %%", "-%d %%")

t("tp_insurance_equip", "Equipment insurance (your farm)", "Geräteversicherung (dein Hof)", "Assurance matériel (votre ferme)",
  "Ubezpieczenie sprzętu (twoje gospodarstwo)", "Seguro de equipos (tu granja)", "Assicurazione mezzi (la tua fattoria)",
  "Materieelverzekering (je boerderij)")
t("tp_tip_insurance_equip",
  "Insures every vehicle and tool your farm owns (not leased or mission vehicles) against tornado damage. Pick the deductible: the higher it is, the lower the monthly premium. Repairs are paid minus the deductible; a total loss pays the vehicle's value. Cover starts about a week (real-life time) after buying.",
  "Versichert jedes Fahrzeug und Gerät deines Hofs (keine geleasten oder Auftragsfahrzeuge) gegen Tornadoschäden. Wähle die Selbstbeteiligung: Je höher sie ist, desto niedriger die Monatsprämie. Reparaturen werden abzüglich der Selbstbeteiligung bezahlt; ein Totalschaden zahlt den Wert des Fahrzeugs. Der Schutz beginnt etwa eine Woche (reale Zeit) nach dem Kauf.",
  "Assure chaque véhicule et outil de votre ferme (hors véhicules loués ou de mission) contre les dégâts des tornades. Choisissez la franchise : plus elle est élevée, plus la prime mensuelle est basse. Les réparations sont payées moins la franchise ; une perte totale paie la valeur du véhicule. La couverture commence environ une semaine (temps réel) après l'achat.",
  "Ubezpiecza każdy pojazd i maszynę twojego gospodarstwa (bez leasingowanych i z zleceń) od szkód po tornadzie. Wybierz udział własny: im wyższy, tym niższa miesięczna składka. Naprawy są opłacane po odjęciu udziału własnego; szkoda całkowita wypłaca wartość pojazdu. Ochrona zaczyna się ok. tydzień (czasu rzeczywistego) po zakupie.",
  "Asegura cada vehículo y apero de tu granja (no los de alquiler ni de misiones) contra daños por tornado. Elige la franquicia: cuanto más alta, más baja la prima mensual. Las reparaciones se pagan menos la franquicia; un siniestro total paga el valor del vehículo. La cobertura empieza una semana (tiempo real) después de la compra.",
  "Assicura ogni veicolo e attrezzo della tua fattoria (non quelli in leasing o delle missioni) contro i danni da tornado. Scegli la franchigia: più è alta, più basso è il premio mensile. Le riparazioni sono pagate meno la franchigia; un danno totale paga il valore del veicolo. La copertura inizia circa una settimana (tempo reale) dopo l'acquisto.",
  "Verzekert elk voertuig en werktuig van je boerderij (geen geleasde of opdrachtvoertuigen) tegen tornadoschade. Kies het eigen risico: hoe hoger, hoe lager de maandpremie. Reparaties worden betaald min het eigen risico; een total loss betaalt de waarde van het voertuig. De dekking begint ongeveer een week (echte tijd) na aankoop.")
t("tp_insurance_equip_none", "No equipment policy", "Keine Geräteversicherung", "Pas d'assurance matériel", "Brak ubezpieczenia sprzętu",
  "Sin seguro de equipos", "Nessuna assicurazione mezzi", "Geen materieelverzekering")
t("tp_insurance_equip_option", "%s deductible - about %s per month", "%s Selbstbeteiligung - etwa %s pro Monat",
  "Franchise %s - environ %s par mois", "Udział własny %s - ok. %s miesięcznie", "Franquicia %s - unos %s al mes",
  "Franchigia %s - circa %s al mese", "%s eigen risico - ongeveer %s per maand")
t("tp_insurance_equip_status", "Equipment policy status", "Status der Geräteversicherung", "État de l'assurance matériel",
  "Status ubezpieczenia sprzętu", "Estado del seguro de equipos", "Stato dell'assicurazione mezzi", "Status materieelverzekering")
t("tp_tip_insurance_equip_status", "Shows your farm's equipment policy: deductible, insured vehicles, their value and the monthly premium.",
  "Zeigt die Geräteversicherung deines Hofs: Selbstbeteiligung, versicherte Fahrzeuge, ihren Wert und die Monatsprämie.",
  "Affiche l'assurance matériel de votre ferme : franchise, véhicules assurés, leur valeur et la prime mensuelle.",
  "Pokazuje ubezpieczenie sprzętu twojego gospodarstwa: udział własny, ubezpieczone pojazdy, ich wartość i miesięczną składkę.",
  "Muestra el seguro de equipos de tu granja: franquicia, vehículos asegurados, su valor y la prima mensual.",
  "Mostra l'assicurazione mezzi della tua fattoria: franchigia, veicoli assicurati, il loro valore e il premio mensile.",
  "Toont de materieelverzekering van je boerderij: eigen risico, verzekerde voertuigen, hun waarde en de maandpremie.")
t("tp_insurance_equip_total", "Total loss to decide", "Zu entscheidender Totalschaden", "Perte totale à décider", "Szkoda całkowita do decyzji",
  "Siniestro total por decidir", "Danno totale da decidere", "Total loss om te beslissen")
t("tp_tip_insurance_equip_total",
  "A vehicle the insurer has declared a total loss. Accept: the full payout and the insurer takes the wreck. Buy back: less money, you keep the vehicle with a Salvage title. Without a choice within a week (real-life time) it is accepted.",
  "Ein Fahrzeug, das die Versicherung zum Totalschaden erklärt hat. Annehmen: die volle Auszahlung, die Versicherung nimmt das Wrack. Zurückkaufen: weniger Geld, du behältst das Fahrzeug mit Bergungstitel. Ohne Entscheidung innerhalb einer Woche (reale Zeit) gilt es als angenommen.",
  "Un véhicule que l'assureur a déclaré en perte totale. Accepter : l'indemnité complète et l'assureur prend l'épave. Racheter : moins d'argent, vous gardez le véhicule avec un titre Épave. Sans choix dans la semaine (temps réel), c'est accepté.",
  "Pojazd uznany przez ubezpieczyciela za szkodę całkowitą. Przyjmij: pełna wypłata, ubezpieczyciel zabiera wrak. Odkup: mniej pieniędzy, zatrzymujesz pojazd z tytułem Wrak. Bez wyboru w ciągu tygodnia (czasu rzeczywistego) zostaje przyjęte.",
  "Un vehículo que la aseguradora ha declarado siniestro total. Aceptar: el pago completo y la aseguradora se lleva los restos. Recomprar: menos dinero, te quedas el vehículo con título de Siniestro. Sin elegir en una semana (tiempo real), se acepta.",
  "Un veicolo che l'assicuratore ha dichiarato danno totale. Accetta: il risarcimento pieno e l'assicuratore prende il relitto. Riacquista: meno soldi, tieni il veicolo con titolo Relitto. Senza scelta entro una settimana (tempo reale) viene accettato.",
  "Een voertuig dat de verzekeraar total loss heeft verklaard. Accepteren: de volle uitkering en de verzekeraar neemt het wrak mee. Terugkopen: minder geld, je houdt het voertuig met de titel Wrak. Zonder keuze binnen een week (echte tijd) wordt het geaccepteerd.")
t("tp_insurance_equip_total_option", "%s: accept %s / buy back %s", "%s: annehmen %s / zurückkaufen %s",
  "%s : accepter %s / racheter %s", "%s: przyjmij %s / odkup %s", "%s: aceptar %s / recomprar %s",
  "%s: accetta %s / riacquista %s", "%s: accepteren %s / terugkopen %s")
t("tp_insurance_equip_total_none", "No total loss to decide", "Kein Totalschaden zu entscheiden", "Aucune perte totale à décider",
  "Brak szkody całkowitej do decyzji", "Ningún siniestro total por decidir", "Nessun danno totale da decidere", "Geen total loss om te beslissen")
t("tp_insurance_equip_accept", "Accept the total loss", "Totalschaden annehmen", "Accepter la perte totale", "Przyjmij szkodę całkowitą",
  "Aceptar el siniestro total", "Accetta il danno totale", "Total loss accepteren")
t("tp_insurance_equip_buyback", "Buy the vehicle back", "Fahrzeug zurückkaufen", "Racheter le véhicule", "Odkup pojazd",
  "Recomprar el vehículo", "Riacquista il veicolo", "Voertuig terugkopen")
t("tp_btn_equip_accept", "Accept", "Annehmen", "Accepter", "Przyjmij", "Aceptar", "Accetta", "Accepteren")
t("tp_btn_equip_buyback", "Buy back", "Zurückkaufen", "Racheter", "Odkup", "Recomprar", "Riacquista", "Terugkopen")
t("tp_confirm_equip_accept", "Accept the total loss? The insurer pays the full amount and takes the vehicle.",
  "Totalschaden annehmen? Die Versicherung zahlt den vollen Betrag und nimmt das Fahrzeug.",
  "Accepter la perte totale ? L'assureur paie le montant complet et prend le véhicule.",
  "Przyjąć szkodę całkowitą? Ubezpieczyciel wypłaca pełną kwotę i zabiera pojazd.",
  "¿Aceptar el siniestro total? La aseguradora paga el importe completo y se lleva el vehículo.",
  "Accettare il danno totale? L'assicuratore paga l'intero importo e prende il veicolo.",
  "Total loss accepteren? De verzekeraar betaalt het volle bedrag en neemt het voertuig mee.")
t("tp_confirm_equip_buyback", "Buy the vehicle back? You get less money and keep it with a Salvage title (lower sell price).",
  "Fahrzeug zurückkaufen? Du bekommst weniger Geld und behältst es mit Bergungstitel (niedrigerer Verkaufspreis).",
  "Racheter le véhicule ? Vous recevez moins d'argent et le gardez avec un titre Épave (prix de vente plus bas).",
  "Odkupić pojazd? Dostajesz mniej pieniędzy i zatrzymujesz go z tytułem Wrak (niższa cena sprzedaży).",
  "¿Recomprar el vehículo? Recibes menos dinero y te lo quedas con título de Siniestro (precio de venta más bajo).",
  "Riacquistare il veicolo? Ricevi meno soldi e lo tieni con titolo Relitto (prezzo di vendita più basso).",
  "Voertuig terugkopen? Je krijgt minder geld en houdt het met de titel Wrak (lagere verkoopprijs).")

t("tp_msg_ins_eq_unknown_deductible", "That deductible is not offered.", "Diese Selbstbeteiligung wird nicht angeboten.",
  "Cette franchise n'est pas proposée.", "Taki udział własny nie jest oferowany.", "Esa franquicia no se ofrece.",
  "Questa franchigia non è offerta.", "Dat eigen risico wordt niet aangeboden.")
t("tp_msg_ins_eq_bought", "Equipment insurance confirmed: %s deductible, %d vehicles, about %s per month. Cover starts in %d d %d h.",
  "Geräteversicherung bestätigt: %s Selbstbeteiligung, %d Fahrzeuge, etwa %s pro Monat. Der Schutz beginnt in %d T %d h.",
  "Assurance matériel confirmée : franchise %s, %d véhicules, environ %s par mois. La couverture commence dans %d j %d h.",
  "Ubezpieczenie sprzętu potwierdzone: udział własny %s, %d pojazdów, ok. %s miesięcznie. Ochrona zaczyna się za %d d %d h.",
  "Seguro de equipos confirmado: franquicia %s, %d vehículos, unos %s al mes. La cobertura empieza en %d d %d h.",
  "Assicurazione mezzi confermata: franchigia %s, %d veicoli, circa %s al mese. La copertura inizia tra %d g %d h.",
  "Materieelverzekering bevestigd: %s eigen risico, %d voertuigen, ongeveer %s per maand. De dekking begint over %d d %d u.")
t("tp_msg_ins_eq_changed", "Equipment insurance changed: %s deductible, %d vehicles, about %s per month.",
  "Geräteversicherung geändert: %s Selbstbeteiligung, %d Fahrzeuge, etwa %s pro Monat.",
  "Assurance matériel modifiée : franchise %s, %d véhicules, environ %s par mois.",
  "Ubezpieczenie sprzętu zmienione: udział własny %s, %d pojazdów, ok. %s miesięcznie.",
  "Seguro de equipos cambiado: franquicia %s, %d vehículos, unos %s al mes.",
  "Assicurazione mezzi modificata: franchigia %s, %d veicoli, circa %s al mese.",
  "Materieelverzekering gewijzigd: %s eigen risico, %d voertuigen, ongeveer %s per maand.")
t("tp_msg_ins_eq_none", "Your farm has no equipment policy.", "Dein Hof hat keine Geräteversicherung.",
  "Votre ferme n'a pas d'assurance matériel.", "Twoje gospodarstwo nie ma ubezpieczenia sprzętu.",
  "Tu granja no tiene seguro de equipos.", "La tua fattoria non ha un'assicurazione mezzi.", "Je boerderij heeft geen materieelverzekering.")
t("tp_msg_ins_eq_cancelled", "Equipment insurance cancelled. Open claims are still handled.",
  "Geräteversicherung gekündigt. Offene Schadensfälle werden noch bearbeitet.",
  "Assurance matériel résiliée. Les sinistres en cours sont encore traités.",
  "Ubezpieczenie sprzętu wypowiedziane. Otwarte szkody są nadal rozpatrywane.",
  "Seguro de equipos cancelado. Los siniestros abiertos se siguen tramitando.",
  "Assicurazione mezzi disdetta. I sinistri aperti vengono ancora gestiti.",
  "Materieelverzekering opgezegd. Openstaande schades worden nog afgehandeld.")
t("tp_msg_ins_eq_active", "Equipment insurance is now active (%s deductible).", "Die Geräteversicherung ist jetzt aktiv (%s Selbstbeteiligung).",
  "L'assurance matériel est maintenant active (franchise %s).", "Ubezpieczenie sprzętu jest teraz aktywne (udział własny %s).",
  "El seguro de equipos ya está activo (franquicia %s).", "L'assicurazione mezzi è ora attiva (franchigia %s).",
  "De materieelverzekering is nu actief (%s eigen risico).")
t("tp_msg_ins_eq_claim_received", "Insurance claim for %s received (repair estimate %s) - an adjuster will inspect it.",
  "Schadensmeldung für %s eingegangen (Reparaturschätzung %s) - ein Gutachter sieht es sich an.",
  "Déclaration de sinistre pour %s reçue (devis de réparation %s) - un expert va l'examiner.",
  "Zgłoszenie szkody dla %s przyjęte (kosztorys naprawy %s) - rzeczoznawca obejrzy pojazd.",
  "Parte de siniestro de %s recibido (presupuesto de reparación %s) - un perito lo revisará.",
  "Denuncia di sinistro per %s ricevuta (preventivo di riparazione %s) - un perito la esaminerà.",
  "Schademelding voor %s ontvangen (reparatieschatting %s) - een expert komt kijken.")
t("tp_msg_ins_eq_claim_inspected", "The adjuster has inspected %s. A decision follows soon.",
  "Der Gutachter hat %s begutachtet. Die Entscheidung folgt bald.",
  "L'expert a examiné %s. Une décision suit bientôt.",
  "Rzeczoznawca obejrzał %s. Decyzja wkrótce.",
  "El perito ha revisado %s. La decisión llegará pronto.",
  "Il perito ha esaminato %s. Una decisione arriverà presto.",
  "De expert heeft %s bekeken. Een beslissing volgt binnenkort.")
t("tp_msg_ins_eq_claim_approved", "Claim for %s approved: estimate %s minus %s deductible - %s will be paid.",
  "Schadensfall %s anerkannt: Schätzung %s abzüglich %s Selbstbeteiligung - %s werden ausgezahlt.",
  "Sinistre de %s accepté : devis %s moins la franchise de %s - %s seront versés.",
  "Szkoda %s uznana: kosztorys %s minus udział własny %s - zostanie wypłacone %s.",
  "Siniestro de %s aprobado: presupuesto %s menos franquicia de %s - se pagarán %s.",
  "Sinistro di %s approvato: preventivo %s meno franchigia di %s - saranno pagati %s.",
  "Schade aan %s goedgekeurd: schatting %s min %s eigen risico - %s wordt uitbetaald.")
t("tp_msg_ins_eq_claim_paid", "Insurance paid for %s: %s.", "Versicherungsleistung für %s: %s.", "Indemnité versée pour %s : %s.",
  "Wypłata ubezpieczenia za %s: %s.", "Indemnización pagada por %s: %s.", "Risarcimento pagato per %s: %s.", "Uitkering voor %s: %s.")
t("tp_msg_ins_eq_claim_deductible", "Claim for %s closed: the repair estimate of %s is within your %s deductible.",
  "Schadensfall %s geschlossen: Die Reparaturschätzung von %s liegt innerhalb deiner Selbstbeteiligung von %s.",
  "Sinistre de %s clos : le devis de réparation de %s ne dépasse pas votre franchise de %s.",
  "Szkoda %s zamknięta: kosztorys naprawy %s mieści się w twoim udziale własnym %s.",
  "Siniestro de %s cerrado: el presupuesto de reparación de %s no supera tu franquicia de %s.",
  "Sinistro di %s chiuso: il preventivo di riparazione di %s rientra nella tua franchigia di %s.",
  "Schade aan %s gesloten: de reparatieschatting van %s valt binnen je eigen risico van %s.")
t("tp_msg_ins_eq_total",
  "%s is a total loss (value %s). Accept %s or buy back %s (Salvage title) - choose in the control panel, Modules, within %d d %d h.",
  "%s ist ein Totalschaden (Wert %s). Annehmen %s oder zurückkaufen %s (Bergungstitel) - entscheide im Kontrollzentrum, Module, in %d T %d h.",
  "%s est une perte totale (valeur %s). Accepter %s ou racheter %s (titre Épave) - choisissez dans le panneau, Modules, sous %d j %d h.",
  "%s to szkoda całkowita (wartość %s). Przyjmij %s lub odkup %s (tytuł Wrak) - wybierz w panelu, Moduły, w ciągu %d d %d h.",
  "%s es un siniestro total (valor %s). Aceptar %s o recomprar %s (título Siniestro) - elige en el panel, Módulos, en %d d %d h.",
  "%s è un danno totale (valore %s). Accetta %s o riacquista %s (titolo Relitto) - scegli nel pannello, Moduli, entro %d g %d h.",
  "%s is total loss (waarde %s). Accepteren %s of terugkopen %s (titel Wrak) - kies in het paneel, Modules, binnen %d d %d u.")
t("tp_msg_ins_eq_total_burned",
  "%s burned out - total loss (value %s). Accept %s or buy back %s (Salvage title) - choose in the control panel, Modules, within %d d %d h.",
  "%s ist ausgebrannt - Totalschaden (Wert %s). Annehmen %s oder zurückkaufen %s (Bergungstitel) - entscheide im Kontrollzentrum, Module, in %d T %d h.",
  "%s a brûlé - perte totale (valeur %s). Accepter %s ou racheter %s (titre Épave) - choisissez dans le panneau, Modules, sous %d j %d h.",
  "%s spłonął - szkoda całkowita (wartość %s). Przyjmij %s lub odkup %s (tytuł Wrak) - wybierz w panelu, Moduły, w ciągu %d d %d h.",
  "%s se ha quemado - siniestro total (valor %s). Aceptar %s o recomprar %s (título Siniestro) - elige en el panel, Módulos, en %d d %d h.",
  "%s è bruciato - danno totale (valore %s). Accetta %s o riacquista %s (titolo Relitto) - scegli nel pannello, Moduli, entro %d g %d h.",
  "%s is uitgebrand - total loss (waarde %s). Accepteren %s of terugkopen %s (titel Wrak) - kies in het paneel, Modules, binnen %d d %d u.")
t("tp_msg_ins_eq_total_reminder", "Reminder: decide on the total loss of %s within %d d %d h (control panel, Modules), or it is accepted.",
  "Erinnerung: Entscheide über den Totalschaden von %s innerhalb von %d T %d h (Kontrollzentrum, Module), sonst gilt er als angenommen.",
  "Rappel : décidez de la perte totale de %s sous %d j %d h (panneau de contrôle, Modules), sinon elle est acceptée.",
  "Przypomnienie: zdecyduj o szkodzie całkowitej %s w ciągu %d d %d h (panel sterowania, Moduły), inaczej zostanie przyjęta.",
  "Recordatorio: decide sobre el siniestro total de %s en %d d %d h (panel de control, Módulos), o se aceptará.",
  "Promemoria: decidi sul danno totale di %s entro %d g %d h (pannello di controllo, Moduli), altrimenti viene accettato.",
  "Herinnering: beslis over de total loss van %s binnen %d d %d u (bedieningspaneel, Modules), anders wordt die geaccepteerd.")
t("tp_msg_ins_eq_settled", "Total loss of %s settled: %s paid, the wreck has been collected.",
  "Totalschaden %s abgeschlossen: %s ausgezahlt, das Wrack wurde abgeholt.",
  "Perte totale de %s réglée : %s versés, l'épave a été enlevée.",
  "Szkoda całkowita %s rozliczona: wypłacono %s, wrak został zabrany.",
  "Siniestro total de %s liquidado: %s pagados, los restos se han retirado.",
  "Danno totale di %s liquidato: %s pagati, il relitto è stato ritirato.",
  "Total loss van %s afgehandeld: %s uitbetaald, het wrak is opgehaald.")
t("tp_msg_ins_eq_settled_auto", "No decision in time: the total loss of %s was accepted, %s paid, the wreck has been collected.",
  "Keine Entscheidung rechtzeitig: Der Totalschaden %s wurde angenommen, %s ausgezahlt, das Wrack wurde abgeholt.",
  "Pas de décision à temps : la perte totale de %s a été acceptée, %s versés, l'épave a été enlevée.",
  "Brak decyzji na czas: szkoda całkowita %s została przyjęta, wypłacono %s, wrak został zabrany.",
  "Sin decisión a tiempo: se aceptó el siniestro total de %s, %s pagados, los restos se han retirado.",
  "Nessuna decisione in tempo: il danno totale di %s è stato accettato, %s pagati, il relitto è stato ritirato.",
  "Geen beslissing op tijd: de total loss van %s is geaccepteerd, %s uitbetaald, het wrak is opgehaald.")
t("tp_msg_ins_eq_bought_back", "%s bought back: %s paid. It has a Salvage title (lower sell price) until it is repaired.",
  "%s zurückgekauft: %s ausgezahlt. Es hat einen Bergungstitel (niedrigerer Verkaufspreis), bis es repariert ist.",
  "%s racheté : %s versés. Il porte un titre Épave (prix de vente plus bas) jusqu'à sa réparation.",
  "%s odkupiony: wypłacono %s. Ma tytuł Wrak (niższa cena sprzedaży), dopóki nie zostanie naprawiony.",
  "%s recomprado: %s pagados. Tiene título de Siniestro (precio de venta más bajo) hasta que se repare.",
  "%s riacquistato: %s pagati. Ha un titolo Relitto (prezzo di vendita più basso) finché non viene riparato.",
  "%s teruggekocht: %s uitbetaald. Het heeft de titel Wrak (lagere verkoopprijs) tot het gerepareerd is.")
t("tp_msg_ins_eq_kept", "Total loss of %s accepted: %s paid. Totalled vehicles are kept (setting), so it stays with a Salvage title.",
  "Totalschaden %s angenommen: %s ausgezahlt. Totalschäden werden behalten (Einstellung), es bleibt mit Bergungstitel.",
  "Perte totale de %s acceptée : %s versés. Les épaves sont conservées (réglage), il reste avec un titre Épave.",
  "Szkoda całkowita %s przyjęta: wypłacono %s. Wraki są zachowywane (ustawienie), pojazd zostaje z tytułem Wrak.",
  "Siniestro total de %s aceptado: %s pagados. Los siniestros totales se conservan (ajuste), se queda con título de Siniestro.",
  "Danno totale di %s accettato: %s pagati. I relitti vengono tenuti (impostazione), resta con titolo Relitto.",
  "Total loss van %s geaccepteerd: %s uitbetaald. Wrakken worden behouden (instelling), het blijft met de titel Wrak.")
t("tp_msg_ins_eq_kept_auto", "No decision in time: the total loss of %s was accepted, %s paid. Totalled vehicles are kept (setting): Salvage title.",
  "Keine Entscheidung rechtzeitig: Der Totalschaden %s wurde angenommen, %s ausgezahlt. Totalschäden werden behalten (Einstellung): Bergungstitel.",
  "Pas de décision à temps : la perte totale de %s a été acceptée, %s versés. Les épaves sont conservées (réglage) : titre Épave.",
  "Brak decyzji na czas: szkoda całkowita %s została przyjęta, wypłacono %s. Wraki są zachowywane (ustawienie): tytuł Wrak.",
  "Sin decisión a tiempo: se aceptó el siniestro total de %s, %s pagados. Los siniestros totales se conservan (ajuste): título de Siniestro.",
  "Nessuna decisione in tempo: il danno totale di %s è stato accettato, %s pagati. I relitti vengono tenuti (impostazione): titolo Relitto.",
  "Geen beslissing op tijd: de total loss van %s is geaccepteerd, %s uitbetaald. Wrakken worden behouden (instelling): titel Wrak.")
t("tp_msg_ins_eq_no_total", "There is no total loss waiting for a decision.", "Es wartet kein Totalschaden auf eine Entscheidung.",
  "Aucune perte totale n'attend de décision.", "Żadna szkoda całkowita nie czeka na decyzję.",
  "No hay ningún siniestro total pendiente de decisión.", "Nessun danno totale in attesa di decisione.",
  "Er wacht geen total loss op een beslissing.")
t("tp_msg_ins_eq_rebuilt", "%s is repaired: its title is now Rebuilt (the sell price stays lower).",
  "%s ist repariert: Der Titel lautet jetzt Wiederaufbau (der Verkaufspreis bleibt niedriger).",
  "%s est réparé : son titre est maintenant Reconstruit (le prix de vente reste plus bas).",
  "%s jest naprawiony: jego tytuł to teraz Odbudowany (cena sprzedaży pozostaje niższa).",
  "%s está reparado: su título ahora es Reconstruido (el precio de venta sigue siendo más bajo).",
  "%s è riparato: il suo titolo è ora Ricostruito (il prezzo di vendita resta più basso).",
  "%s is gerepareerd: de titel is nu Herbouwd (de verkoopprijs blijft lager).")
t("tp_msg_ins_eq_none_status", "No equipment policy. Choose a deductible to insure every vehicle and tool your farm owns.",
  "Keine Geräteversicherung. Wähle eine Selbstbeteiligung, um alle Fahrzeuge und Geräte deines Hofs zu versichern.",
  "Pas d'assurance matériel. Choisissez une franchise pour assurer tous les véhicules et outils de votre ferme.",
  "Brak ubezpieczenia sprzętu. Wybierz udział własny, aby ubezpieczyć wszystkie pojazdy i maszyny gospodarstwa.",
  "Sin seguro de equipos. Elige una franquicia para asegurar todos los vehículos y aperos de tu granja.",
  "Nessuna assicurazione mezzi. Scegli una franchigia per assicurare tutti i veicoli e gli attrezzi della tua fattoria.",
  "Geen materieelverzekering. Kies een eigen risico om alle voertuigen en werktuigen van je boerderij te verzekeren.")
t("tp_msg_ins_eq_status", "Equipment insurance: %s deductible (%s) - %d vehicles, value %s, about %s per month, %d total losses to decide.",
  "Geräteversicherung: %s Selbstbeteiligung (%s) - %d Fahrzeuge, Wert %s, etwa %s pro Monat, %d Totalschäden zu entscheiden.",
  "Assurance matériel : franchise %s (%s) - %d véhicules, valeur %s, environ %s par mois, %d pertes totales à décider.",
  "Ubezpieczenie sprzętu: udział własny %s (%s) - %d pojazdów, wartość %s, ok. %s miesięcznie, %d szkód całkowitych do decyzji.",
  "Seguro de equipos: franquicia %s (%s) - %d vehículos, valor %s, unos %s al mes, %d siniestros totales por decidir.",
  "Assicurazione mezzi: franchigia %s (%s) - %d veicoli, valore %s, circa %s al mese, %d danni totali da decidere.",
  "Materieelverzekering: %s eigen risico (%s) - %d voertuigen, waarde %s, ongeveer %s per maand, %d total losses om te beslissen.")

# =====================================================================================================
# MESSAGES TAB (full-width table)
# =====================================================================================================
t("tp_tab_messages_new", "Messages (%d)", "Nachrichten (%d)", "Messages (%d)", "Wiadomości (%d)", "Mensajes (%d)", "Messaggi (%d)",
  "Berichten (%d)")
t("tp_msg_recent_tab", "Recent (%d)", "Neueste (%d)", "Récents (%d)", "Najnowsze (%d)", "Recientes (%d)", "Recenti (%d)", "Recent (%d)")
t("tp_msg_recent_tab_new", "Recent (%d, %d new)", "Neueste (%d, %d neu)", "Récents (%d, %d nouv.)", "Najnowsze (%d, %d nowe)",
  "Recientes (%d, %d nuevos)", "Recenti (%d, %d nuovi)", "Recent (%d, %d nieuw)")
t("tp_msg_saved_tab", "Saved (%d)", "Gespeichert (%d)", "Enregistrés (%d)", "Zapisane (%d)", "Guardados (%d)", "Salvati (%d)",
  "Bewaard (%d)")
t("tp_msg_filter", "Type", "Art", "Type", "Rodzaj", "Tipo", "Tipo", "Soort")
t("tp_msg_col_time", "Time", "Zeit", "Heure", "Czas", "Hora", "Ora", "Tijd")
t("tp_msg_col_type", "Type", "Art", "Type", "Rodzaj", "Tipo", "Tipo", "Soort")
t("tp_msg_col_message", "Message", "Nachricht", "Message", "Wiadomość", "Mensaje", "Messaggio", "Bericht")
t("tp_msg_selected", "Selected message", "Ausgewählte Nachricht", "Message sélectionné", "Wybrana wiadomość", "Mensaje seleccionado",
  "Messaggio selezionato", "Gekozen bericht")
t("tp_msg_showing", "Showing %d - %d of %d", "Zeige %d - %d von %d", "Affichage %d - %d sur %d", "Pozycje %d - %d z %d",
  "Mostrando %d - %d de %d", "Mostrati %d - %d di %d", "%d - %d van %d")
t("tp_msg_none_recent", "No recent messages (they are kept for 24 in-game hours).",
  "Keine neuen Nachrichten (sie bleiben 24 Spielstunden).", "Aucun message récent (ils restent 24 heures de jeu).",
  "Brak najnowszych wiadomości (są przechowywane 24 godziny gry).", "No hay mensajes recientes (se guardan 24 horas de juego).",
  "Nessun messaggio recente (restano 24 ore di gioco).", "Geen recente berichten (ze blijven 24 speluren).")
t("tp_msg_none_saved", "No saved messages.", "Keine gespeicherten Nachrichten.", "Aucun message enregistré.",
  "Brak zapisanych wiadomości.", "No hay mensajes guardados.", "Nessun messaggio salvato.", "Geen bewaarde berichten.")
t("tp_msg_hidden", "%d messages hidden by the type filter - set Type to All to see them.",
  "%d Nachrichten durch den Artfilter ausgeblendet - Art auf Alle stellen, um sie zu sehen.",
  "%d messages masqués par le filtre de type - choisissez Tous pour les voir.",
  "%d wiadomości ukrytych przez filtr rodzaju - ustaw Wszystkie, aby je zobaczyć.",
  "%d mensajes ocultos por el filtro de tipo - elige Todos para verlos.",
  "%d messaggi nascosti dal filtro tipo - scegli Tutti per vederli.",
  "%d berichten verborgen door het soortfilter - kies Alle om ze te zien.")
t("tp_msg_hidden_short", "(%d hidden by the filter)", "(%d durch Filter ausgeblendet)", "(%d masqués par le filtre)",
  "(%d ukrytych przez filtr)", "(%d ocultos por el filtro)", "(%d nascosti dal filtro)", "(%d verborgen door filter)")
t("tp_btn_scroll_up", "Up", "Hoch", "Haut", "W górę", "Arriba", "Su", "Omhoog")
t("tp_btn_scroll_down", "Down", "Runter", "Bas", "W dół", "Abajo", "Giù", "Omlaag")
t("tp_btn_remove_all", "Remove all saved", "Alle gespeicherten löschen", "Supprimer tous", "Usuń wszystkie zapisane",
  "Eliminar todos", "Rimuovi tutti", "Alle bewaarde wissen")
t("tp_confirm_msg_remove_all", "Remove ALL saved messages of your farm?", "ALLE gespeicherten Nachrichten deines Hofs löschen?",
  "Supprimer TOUS les messages enregistrés de votre ferme ?", "Usunąć WSZYSTKIE zapisane wiadomości gospodarstwa?",
  "¿Eliminar TODOS los mensajes guardados de tu granja?", "Rimuovere TUTTI i messaggi salvati della fattoria?",
  "ALLE bewaarde berichten van je boerderij wissen?")
t("tp_msg_removed_all_done", "All saved messages removed.", "Alle gespeicherten Nachrichten gelöscht.",
  "Tous les messages enregistrés supprimés.", "Usunięto wszystkie zapisane wiadomości.", "Todos los mensajes guardados eliminados.",
  "Tutti i messaggi salvati rimossi.", "Alle bewaarde berichten gewist.")
t("tp_msgtype_all", "All", "Alle", "Tous", "Wszystkie", "Todos", "Tutti", "Alle")
t("tp_msgtype_insurance", "Insurance", "Versicherung", "Assurance", "Ubezpieczenie", "Seguro", "Assicurazione", "Verzekering")
t("tp_msgtype_report", "Storm report", "Unwetterbericht", "Rapport d'orage", "Raport burzy", "Informe de tormenta",
  "Rapporto tempesta", "Stormrapport")
t("tp_msgtype_hazard", "Hazard", "Naturgefahr", "Aléa", "Zagrożenie", "Riesgo natural", "Calamità", "Natuurgevaar")
t("tp_msgtype_tornado", "Tornado", "Tornado", "Tornade", "Tornado", "Tornado", "Tornado", "Tornado")
t("tp_msgtype_recovery", "Recovery", "Bergung", "Dépannage", "Holowanie", "Rescate", "Soccorso", "Berging")
t("tp_msgtype_other", "Other", "Sonstiges", "Autre", "Inne", "Otros", "Altro", "Overig")

# =====================================================================================================
# INSURANCE - LIVESTOCK
# =====================================================================================================
t("tp_insurance_livestock", "Livestock insurance (your farm)", "Tierversicherung (dein Hof)", "Assurance bétail (votre ferme)",
  "Ubezpieczenie zwierząt (twoje gospodarstwo)", "Seguro de ganado (tu granja)", "Assicurazione bestiame (la tua fattoria)",
  "Veeverzekering (je boerderij)")
t("tp_tip_insurance_livestock",
  "Insures every animal of your farm against tornado losses at its value when it dies (age and health count). 5 percent of each claim is your excess. In the United States the USDA Livestock Indemnity Program also pays 75 percent of the market value for free; the policy pays the rest. Animals only die in a tornado when the Livestock module is on.",
  "Versichert jedes Tier deines Hofs gegen Tornadoverluste zu seinem Wert beim Tod (Alter und Gesundheit zählen). 5 Prozent jedes Schadens trägst du selbst. In den USA zahlt das USDA Livestock Indemnity Program zusätzlich kostenlos 75 Prozent des Marktwerts; die Police zahlt den Rest. Tiere sterben nur bei eingeschaltetem Tiermodul.",
  "Assure chaque animal de votre ferme contre les pertes dues aux tornades à sa valeur au moment de sa mort (âge et santé comptent). 5 pour cent de chaque sinistre restent à votre charge. Aux États-Unis, le Livestock Indemnity Program de l'USDA paie aussi gratuitement 75 pour cent de la valeur marchande ; le contrat paie le reste. Les animaux ne meurent que si le module bétail est activé.",
  "Ubezpiecza każde zwierzę gospodarstwa od strat po tornadzie według jego wartości w chwili śmierci (liczy się wiek i zdrowie). 5 procent każdej szkody to twój udział własny. W USA program USDA Livestock Indemnity Program dodatkowo bezpłatnie wypłaca 75 procent wartości rynkowej; polisa pokrywa resztę. Zwierzęta giną tylko przy włączonym module zwierząt.",
  "Asegura cada animal de tu granja contra pérdidas por tornado según su valor al morir (cuentan la edad y la salud). El 5 por ciento de cada siniestro es tu franquicia. En EE. UU. el Livestock Indemnity Program del USDA paga además gratis el 75 por ciento del valor de mercado; la póliza paga el resto. Los animales solo mueren con el módulo de ganado activado.",
  "Assicura ogni animale della fattoria contro le perdite da tornado al suo valore al momento della morte (contano età e salute). Il 5 per cento di ogni sinistro è la tua franchigia. Negli Stati Uniti il Livestock Indemnity Program dell'USDA paga inoltre gratis il 75 per cento del valore di mercato; la polizza paga il resto. Gli animali muoiono solo con il modulo bestiame attivo.",
  "Verzekert elk dier van je boerderij tegen tornadoverlies tegen zijn waarde bij overlijden (leeftijd en gezondheid tellen). 5 procent van elke schade is je eigen risico. In de VS betaalt het USDA Livestock Indemnity Program daarnaast gratis 75 procent van de marktwaarde; de polis betaalt de rest. Dieren sterven alleen als de veemodule aan staat.")
t("tp_insurance_livestock_none", "No livestock policy", "Keine Tierversicherung", "Pas d'assurance bétail", "Brak ubezpieczenia zwierząt",
  "Sin seguro de ganado", "Nessuna assicurazione bestiame", "Geen veeverzekering")
t("tp_insurance_livestock_option", "Insure %d animals (%s) - about %s per month", "%d Tiere versichern (%s) - etwa %s pro Monat",
  "Assurer %d animaux (%s) - environ %s par mois", "Ubezpiecz %d zwierząt (%s) - ok. %s miesięcznie",
  "Asegurar %d animales (%s) - unos %s al mes", "Assicura %d animali (%s) - circa %s al mese",
  "%d dieren verzekeren (%s) - ongeveer %s per maand")
t("tp_insurance_livestock_empty", "Insure all animals (no animals yet)", "Alle Tiere versichern (noch keine Tiere)",
  "Assurer tous les animaux (pas encore d'animaux)", "Ubezpiecz wszystkie zwierzęta (brak zwierząt)",
  "Asegurar todos los animales (aún sin animales)", "Assicura tutti gli animali (ancora nessun animale)",
  "Alle dieren verzekeren (nog geen dieren)")
t("tp_insurance_livestock_status", "Livestock policy status", "Status der Tierversicherung", "État de l'assurance bétail",
  "Status ubezpieczenia zwierząt", "Estado del seguro de ganado", "Stato dell'assicurazione bestiame", "Status veeverzekering")
t("tp_ins_status_none", "no policy", "keine Police", "pas de contrat", "brak polisy", "sin póliza", "nessuna polizza", "geen polis")
t("tp_msg_ins_lv_status", "Livestock insurance: %s - %d animals worth %s, about %s per month. %s",
  "Tierversicherung: %s - %d Tiere im Wert von %s, etwa %s pro Monat. %s",
  "Assurance bétail : %s - %d animaux d'une valeur de %s, environ %s par mois. %s",
  "Ubezpieczenie zwierząt: %s - %d zwierząt o wartości %s, ok. %s miesięcznie. %s",
  "Seguro de ganado: %s - %d animales por valor de %s, unos %s al mes. %s",
  "Assicurazione bestiame: %s - %d animali del valore di %s, circa %s al mese. %s",
  "Veeverzekering: %s - %d dieren ter waarde van %s, ongeveer %s per maand. %s")
t("tp_ins_lv_gov_us", "State programme: the USDA Livestock Indemnity Program pays 75 percent of the market value for animals a tornado kills.",
  "Staatliches Programm: Das USDA Livestock Indemnity Program zahlt 75 Prozent des Marktwerts für Tiere, die ein Tornado tötet.",
  "Programme public : le Livestock Indemnity Program de l'USDA paie 75 pour cent de la valeur marchande des animaux tués par une tornade.",
  "Program państwowy: USDA Livestock Indemnity Program wypłaca 75 procent wartości rynkowej zwierząt zabitych przez tornado.",
  "Programa estatal: el Livestock Indemnity Program del USDA paga el 75 por ciento del valor de mercado de los animales muertos por un tornado.",
  "Programma statale: il Livestock Indemnity Program dell'USDA paga il 75 per cento del valore di mercato degli animali uccisi da un tornado.",
  "Overheidsregeling: het USDA Livestock Indemnity Program betaalt 75 procent van de marktwaarde voor dieren die een tornado doodt.")
t("tp_ins_lv_gov_none", "State programme: none in this country.", "Staatliches Programm: keines in diesem Land.",
  "Programme public : aucun dans ce pays.", "Program państwowy: brak w tym kraju.", "Programa estatal: ninguno en este país.",
  "Programma statale: nessuno in questo paese.", "Overheidsregeling: geen in dit land.")
t("tp_ins_lv_husbandry_off", "Note: animals only die in a tornado when the Livestock module is on (Modules tab).",
  "Hinweis: Tiere sterben nur bei eingeschaltetem Tiermodul (Reiter Module).",
  "Remarque : les animaux ne meurent dans une tornade que si le module bétail est activé (onglet Modules).",
  "Uwaga: zwierzęta giną w tornadzie tylko przy włączonym module zwierząt (karta Moduły).",
  "Nota: los animales solo mueren en un tornado con el módulo de ganado activado (pestaña Módulos).",
  "Nota: gli animali muoiono in un tornado solo con il modulo bestiame attivo (scheda Moduli).",
  "Let op: dieren sterven alleen in een tornado als de veemodule aan staat (tabblad Modules).")
t("tp_msg_ins_lv_already", "Your farm already has a livestock policy.", "Dein Hof hat bereits eine Tierversicherung.",
  "Votre ferme a déjà une assurance bétail.", "Twoje gospodarstwo ma już ubezpieczenie zwierząt.",
  "Tu granja ya tiene un seguro de ganado.", "La tua fattoria ha già un'assicurazione bestiame.", "Je boerderij heeft al een veeverzekering.")
t("tp_msg_ins_lv_bought", "Livestock insurance confirmed: %d animals, about %s per month. Cover starts in %d d %d h.",
  "Tierversicherung bestätigt: %d Tiere, etwa %s pro Monat. Der Schutz beginnt in %d T %d h.",
  "Assurance bétail confirmée : %d animaux, environ %s par mois. La couverture commence dans %d j %d h.",
  "Ubezpieczenie zwierząt potwierdzone: %d zwierząt, ok. %s miesięcznie. Ochrona zaczyna się za %d d %d h.",
  "Seguro de ganado confirmado: %d animales, unos %s al mes. La cobertura empieza en %d d %d h.",
  "Assicurazione bestiame confermata: %d animali, circa %s al mese. La copertura inizia tra %d g %d h.",
  "Veeverzekering bevestigd: %d dieren, ongeveer %s per maand. De dekking begint over %d d %d u.")
t("tp_msg_ins_lv_none", "Your farm has no livestock policy.", "Dein Hof hat keine Tierversicherung.",
  "Votre ferme n'a pas d'assurance bétail.", "Twoje gospodarstwo nie ma ubezpieczenia zwierząt.",
  "Tu granja no tiene seguro de ganado.", "La tua fattoria non ha un'assicurazione bestiame.", "Je boerderij heeft geen veeverzekering.")
t("tp_msg_ins_lv_cancelled", "Livestock insurance cancelled. Open claims are still handled.",
  "Tierversicherung gekündigt. Offene Schadensfälle werden noch bearbeitet.",
  "Assurance bétail résiliée. Les sinistres en cours sont encore traités.",
  "Ubezpieczenie zwierząt wypowiedziane. Otwarte szkody są nadal rozpatrywane.",
  "Seguro de ganado cancelado. Los siniestros abiertos se siguen tramitando.",
  "Assicurazione bestiame disdetta. I sinistri aperti vengono ancora gestiti.",
  "Veeverzekering opgezegd. Openstaande schades worden nog afgehandeld.")
t("tp_msg_ins_lv_active", "Livestock insurance is now active.", "Die Tierversicherung ist jetzt aktiv.",
  "L'assurance bétail est maintenant active.", "Ubezpieczenie zwierząt jest teraz aktywne.", "El seguro de ganado ya está activo.",
  "L'assicurazione bestiame è ora attiva.", "De veeverzekering is nu actief.")
t("tp_msg_ins_lv_claim_received", "Livestock claim received: %d animals lost at %s (value %s) - an adjuster will visit.",
  "Tierschaden gemeldet: %d Tiere verloren bei %s (Wert %s) - ein Gutachter kommt.",
  "Sinistre bétail reçu : %d animaux perdus à %s (valeur %s) - un expert va passer.",
  "Zgłoszenie szkody zwierząt: %d zwierząt utraconych w %s (wartość %s) - przyjedzie rzeczoznawca.",
  "Siniestro de ganado recibido: %d animales perdidos en %s (valor %s) - un perito lo visitará.",
  "Sinistro bestiame ricevuto: %d animali persi a %s (valore %s) - passerà un perito.",
  "Veeschade ontvangen: %d dieren verloren bij %s (waarde %s) - een expert komt langs.")
t("tp_msg_ins_lv_claim_inspected", "The adjuster has visited %s. A decision follows soon.",
  "Der Gutachter war bei %s. Die Entscheidung folgt bald.", "L'expert est passé à %s. Une décision suit bientôt.",
  "Rzeczoznawca odwiedził %s. Decyzja wkrótce.", "El perito ha visitado %s. La decisión llegará pronto.",
  "Il perito ha visitato %s. Una decisione arriverà presto.", "De expert is bij %s geweest. Een beslissing volgt binnenkort.")
t("tp_msg_ins_lv_gov_approved", "USDA Livestock Indemnity Program: %d animals lost at %s - %s approved (75 percent of the market value).",
  "USDA Livestock Indemnity Program: %d Tiere verloren bei %s - %s bewilligt (75 Prozent des Marktwerts).",
  "Livestock Indemnity Program de l'USDA : %d animaux perdus à %s - %s accordés (75 pour cent de la valeur marchande).",
  "USDA Livestock Indemnity Program: %d zwierząt utraconych w %s - przyznano %s (75 procent wartości rynkowej).",
  "Livestock Indemnity Program del USDA: %d animales perdidos en %s - %s aprobados (75 por ciento del valor de mercado).",
  "Livestock Indemnity Program dell'USDA: %d animali persi a %s - %s approvati (75 per cento del valore di mercato).",
  "USDA Livestock Indemnity Program: %d dieren verloren bij %s - %s toegekend (75 procent van de marktwaarde).")
t("tp_msg_ins_lv_claim_approved", "Livestock claim for %s approved: insured value %s - %s will be paid (5 percent excess and the state payment deducted).",
  "Tierschaden %s anerkannt: versicherter Wert %s - %s werden ausgezahlt (abzüglich 5 Prozent Selbstbeteiligung und der staatlichen Zahlung).",
  "Sinistre bétail de %s accepté : valeur assurée %s - %s seront versés (franchise de 5 pour cent et paiement public déduits).",
  "Szkoda zwierząt w %s uznana: wartość ubezpieczenia %s - zostanie wypłacone %s (po odjęciu 5 procent udziału własnego i wypłaty państwowej).",
  "Siniestro de ganado de %s aprobado: valor asegurado %s - se pagarán %s (descontados el 5 por ciento de franquicia y el pago estatal).",
  "Sinistro bestiame di %s approvato: valore assicurato %s - saranno pagati %s (dedotti il 5 per cento di franchigia e il pagamento statale).",
  "Veeschade %s goedgekeurd: verzekerde waarde %s - %s wordt uitbetaald (min 5 procent eigen risico en de overheidsuitkering).")
t("tp_msg_ins_lv_gov_paid", "USDA Livestock Indemnity Program paid %s.", "Das USDA Livestock Indemnity Program hat %s gezahlt.",
  "Le Livestock Indemnity Program de l'USDA a versé %s.", "USDA Livestock Indemnity Program wypłacił %s.",
  "El Livestock Indemnity Program del USDA ha pagado %s.", "Il Livestock Indemnity Program dell'USDA ha pagato %s.",
  "Het USDA Livestock Indemnity Program heeft %s betaald.")
t("tp_msg_ins_lv_claim_paid", "Livestock insurance paid for %s: %s.", "Tierversicherung zahlte für %s: %s.",
  "Assurance bétail versée pour %s : %s.", "Wypłata ubezpieczenia zwierząt za %s: %s.", "El seguro de ganado pagó por %s: %s.",
  "L'assicurazione bestiame ha pagato per %s: %s.", "Veeverzekering betaald voor %s: %s.")

# =====================================================================================================
# INSURANCE TAB (Start here, My policies)
# =====================================================================================================
t("tp_tab_insurance", "Insurance", "Versicherung", "Assurance", "Ubezpieczenia", "Seguros", "Assicurazioni", "Verzekering")
t("tp_ins_nav_start", "Start here", "Hier starten", "Commencer ici", "Zacznij tutaj", "Empieza aquí", "Inizia qui", "Begin hier")
t("tp_ins_nav_policies", "My policies", "Meine Policen", "Mes contrats", "Moje polisy", "Mis pólizas", "Le mie polizze", "Mijn polissen")
t("tp_ins_start_title", "Choose your coverage", "Wähle deinen Versicherungsschutz", "Choisissez votre couverture", "Wybierz zakres ochrony",
  "Elige tu cobertura", "Scegli la copertura", "Kies je dekking")
t("tp_ins_crop", "Crop insurance", "Ernteversicherung", "Assurance récolte", "Ubezpieczenie upraw", "Seguro de cosecha",
  "Assicurazione raccolto", "Oogstverzekering")
t("tp_ins_equip", "Equipment insurance", "Geräteversicherung", "Assurance matériel", "Ubezpieczenie sprzętu", "Seguro de equipos",
  "Assicurazione mezzi", "Materieelverzekering")
t("tp_ins_livestock", "Livestock insurance", "Tierversicherung", "Assurance bétail", "Ubezpieczenie zwierząt", "Seguro de ganado",
  "Assicurazione bestiame", "Veeverzekering")
t("tp_ins_not_included", "Not included", "Nicht enthalten", "Non inclus", "Nie wybrano", "No incluido", "Non incluso", "Niet inbegrepen")
t("tp_ins_deductible_option", "%s deductible", "%s Selbstbeteiligung", "Franchise %s", "Udział własny %s", "Franquicia %s",
  "Franchigia %s", "%s eigen risico")
t("tp_ins_livestock_all", "All animals", "Alle Tiere", "Tous les animaux", "Wszystkie zwierzęta", "Todos los animales",
  "Tutti gli animali", "Alle dieren")
t("tp_btn_get_quote", "Get quote", "Angebot", "Devis", "Wycena", "Presupuesto", "Preventivo", "Offerte")
t("tp_btn_confirm_start", "Confirm & start", "Bestätigen & starten", "Confirmer et démarrer", "Potwierdź i rozpocznij",
  "Confirmar e iniciar", "Conferma e avvia", "Bevestigen & starten")
t("tp_btn_cancel_policy", "Cancel policy", "Police kündigen", "Résilier", "Wypowiedz polisę", "Cancelar póliza", "Disdici polizza",
  "Polis opzeggen")
t("tp_ins_q_crop", "Crop - %s at %d %%: %d fields, insured value %s, about %s per month.",
  "Ernte - %s mit %d %%: %d Felder, Versicherungssumme %s, etwa %s pro Monat.",
  "Récolte - %s à %d %% : %d champs, valeur assurée %s, environ %s par mois.",
  "Uprawy - %s, %d %%: %d pól, suma ubezpieczenia %s, ok. %s miesięcznie.",
  "Cosecha - %s al %d %%: %d campos, valor asegurado %s, unos %s al mes.",
  "Raccolto - %s al %d %%: %d campi, valore assicurato %s, circa %s al mese.",
  "Oogst - %s op %d %%: %d velden, verzekerde waarde %s, ongeveer %s per maand.")
t("tp_ins_q_unchanged", "(your current policy - no change)", "(deine aktuelle Police - keine Änderung)",
  "(votre contrat actuel - aucun changement)", "(obecna polisa - bez zmian)", "(tu póliza actual - sin cambios)",
  "(la tua polizza attuale - nessuna modifica)", "(je huidige polis - geen wijziging)")
t("tp_ins_q_change", "(change: about %s -> %s per month)", "(Änderung: etwa %s -> %s pro Monat)", "(changement : environ %s -> %s par mois)",
  "(zmiana: ok. %s -> %s miesięcznie)", "(cambio: unos %s -> %s al mes)", "(modifica: circa %s -> %s al mese)",
  "(wijziging: ongeveer %s -> %s per maand)")
t("tp_ins_q_sales_closed", "(crop policies can only be bought or changed in late winter / early spring - not sent)",
  "(Ernteversicherungen nur im Spätwinter / Frühlingsanfang - nicht gesendet)",
  "(contrats récolte seulement en fin d'hiver / début de printemps - non envoyé)",
  "(polisy upraw tylko późną zimą / wczesną wiosną - nie wysłano)",
  "(pólizas de cosecha solo a finales de invierno / principios de primavera - no enviado)",
  "(polizze raccolto solo a fine inverno / inizio primavera - non inviato)",
  "(oogstpolissen alleen in de late winter / vroege lente - niet verzonden)")
t("tp_ins_q_uninsurable", "(%d fields with crops that cannot be insured)", "(%d Felder mit nicht versicherbaren Kulturen)",
  "(%d champs avec des cultures non assurables)", "(%d pól z uprawami bez ubezpieczenia)", "(%d campos con cultivos no asegurables)",
  "(%d campi con colture non assicurabili)", "(%d velden met onverzekerbare gewassen)")
t("tp_ins_q_crop_kept", "Crop - your current policy stays (cancel it under My policies).",
  "Ernte - deine aktuelle Police bleibt (kündigen unter Meine Policen).",
  "Récolte - votre contrat actuel reste (résiliez-le dans Mes contrats).",
  "Uprawy - obecna polisa zostaje (wypowiedz ją w Moich polisach).",
  "Cosecha - tu póliza actual sigue (cancélala en Mis pólizas).",
  "Raccolto - la polizza attuale resta (disdicila in Le mie polizze).",
  "Oogst - je huidige polis blijft (opzeggen onder Mijn polissen).")
t("tp_ins_q_equip", "Equipment - %s deductible: %d vehicles worth %s, about %s per month.",
  "Geräte - %s Selbstbeteiligung: %d Fahrzeuge im Wert von %s, etwa %s pro Monat.",
  "Matériel - franchise %s : %d véhicules d'une valeur de %s, environ %s par mois.",
  "Sprzęt - udział własny %s: %d pojazdów o wartości %s, ok. %s miesięcznie.",
  "Equipos - franquicia %s: %d vehículos por valor de %s, unos %s al mes.",
  "Mezzi - franchigia %s: %d veicoli del valore di %s, circa %s al mese.",
  "Materieel - %s eigen risico: %d voertuigen ter waarde van %s, ongeveer %s per maand.")
t("tp_ins_q_equip_kept", "Equipment - your current policy stays (cancel it under My policies).",
  "Geräte - deine aktuelle Police bleibt (kündigen unter Meine Policen).",
  "Matériel - votre contrat actuel reste (résiliez-le dans Mes contrats).",
  "Sprzęt - obecna polisa zostaje (wypowiedz ją w Moich polisach).",
  "Equipos - tu póliza actual sigue (cancélala en Mis pólizas).",
  "Mezzi - la polizza attuale resta (disdicila in Le mie polizze).",
  "Materieel - je huidige polis blijft (opzeggen onder Mijn polissen).")
t("tp_ins_q_livestock", "Livestock - %d animals worth %s, about %s per month.",
  "Tiere - %d Tiere im Wert von %s, etwa %s pro Monat.", "Bétail - %d animaux d'une valeur de %s, environ %s par mois.",
  "Zwierzęta - %d zwierząt o wartości %s, ok. %s miesięcznie.", "Ganado - %d animales por valor de %s, unos %s al mes.",
  "Bestiame - %d animali del valore di %s, circa %s al mese.", "Vee - %d dieren ter waarde van %s, ongeveer %s per maand.")
t("tp_ins_q_livestock_gov", "(the USDA programme also pays 75 percent of the market value)",
  "(das USDA-Programm zahlt zusätzlich 75 Prozent des Marktwerts)", "(le programme de l'USDA paie aussi 75 pour cent de la valeur marchande)",
  "(program USDA wypłaca też 75 procent wartości rynkowej)", "(el programa del USDA paga además el 75 por ciento del valor de mercado)",
  "(il programma USDA paga anche il 75 per cento del valore di mercato)", "(het USDA-programma betaalt daarnaast 75 procent van de marktwaarde)")
t("tp_ins_q_livestock_kept", "Livestock - your current policy stays (cancel it under My policies).",
  "Tiere - deine aktuelle Police bleibt (kündigen unter Meine Policen).",
  "Bétail - votre contrat actuel reste (résiliez-le dans Mes contrats).",
  "Zwierzęta - obecna polisa zostaje (wypowiedz ją w Moich polisach).",
  "Ganado - tu póliza actual sigue (cancélala en Mis pólizas).",
  "Bestiame - la polizza attuale resta (disdicila in Le mie polizze).",
  "Vee - je huidige polis blijft (opzeggen onder Mijn polissen).")
t("tp_ins_q_nothing", "Nothing chosen yet - pick the coverage above and press Get quote.",
  "Noch nichts gewählt - wähle oben den Schutz und drücke Angebot.", "Rien de choisi - choisissez la couverture ci-dessus puis Devis.",
  "Nic nie wybrano - wybierz ochronę powyżej i naciśnij Wycena.", "Nada elegido aún - elige la cobertura arriba y pulsa Presupuesto.",
  "Niente scelto - scegli la copertura sopra e premi Preventivo.", "Nog niets gekozen - kies hierboven de dekking en druk op Offerte.")
t("tp_ins_q_total", "Total: about %s per month (money scale applied).", "Gesamt: etwa %s pro Monat (Geldskala berücksichtigt).",
  "Total : environ %s par mois (échelle d'argent appliquée).", "Razem: ok. %s miesięcznie (z uwzględnieniem skali pieniędzy).",
  "Total: unos %s al mes (escala de dinero aplicada).", "Totale: circa %s al mese (scala del denaro applicata).",
  "Totaal: ongeveer %s per maand (geldschaal toegepast).")
t("tp_ins_q_wait", "New cover starts about a week (real-life time) after you confirm; changes to a policy apply at once.",
  "Neuer Schutz beginnt etwa eine Woche (reale Zeit) nach der Bestätigung; Änderungen gelten sofort.",
  "Une nouvelle couverture commence environ une semaine (temps réel) après confirmation ; les changements s'appliquent tout de suite.",
  "Nowa ochrona zaczyna się ok. tydzień (czasu rzeczywistego) po potwierdzeniu; zmiany obowiązują od razu.",
  "La nueva cobertura empieza una semana (tiempo real) después de confirmar; los cambios se aplican al momento.",
  "La nuova copertura inizia circa una settimana (tempo reale) dopo la conferma; le modifiche valgono subito.",
  "Nieuwe dekking begint ongeveer een week (echte tijd) na bevestiging; wijzigingen gelden meteen.")
t("tp_ins_q_hint", "Choose the coverage above, then press Get quote to see the price before you confirm.",
  "Wähle oben den Schutz und drücke Angebot, um den Preis vor der Bestätigung zu sehen.",
  "Choisissez la couverture ci-dessus, puis Devis pour voir le prix avant de confirmer.",
  "Wybierz ochronę powyżej, a potem Wycena, aby zobaczyć cenę przed potwierdzeniem.",
  "Elige la cobertura arriba y pulsa Presupuesto para ver el precio antes de confirmar.",
  "Scegli la copertura sopra, poi premi Preventivo per vedere il prezzo prima di confermare.",
  "Kies hierboven de dekking en druk op Offerte om de prijs te zien voordat je bevestigt.")
t("tp_ins_q_nothing_new", "Nothing new to start or change.", "Nichts Neues zu starten oder zu ändern.",
  "Rien de nouveau à démarrer ou modifier.", "Nic nowego do rozpoczęcia ani zmiany.", "Nada nuevo que iniciar o cambiar.",
  "Niente di nuovo da avviare o modificare.", "Niets nieuws om te starten of te wijzigen.")
t("tp_ins_confirm_sent", "%d requests sent - the insurer's letters confirm each policy.",
  "%d Anfragen gesendet - die Briefe der Versicherung bestätigen jede Police.",
  "%d demandes envoyées - les lettres de l'assureur confirment chaque contrat.",
  "Wysłano %d wniosków - listy ubezpieczyciela potwierdzą każdą polisę.",
  "%d solicitudes enviadas - las cartas de la aseguradora confirman cada póliza.",
  "%d richieste inviate - le lettere dell'assicuratore confermano ogni polizza.",
  "%d aanvragen verzonden - de brieven van de verzekeraar bevestigen elke polis.")
t("tp_confirm_ins_start", "Start or change the quoted policies? The premiums are charged every month.",
  "Die angebotenen Policen starten oder ändern? Die Prämien werden monatlich abgebucht.",
  "Démarrer ou modifier les contrats proposés ? Les primes sont prélevées chaque mois.",
  "Rozpocząć lub zmienić wycenione polisy? Składki są pobierane co miesiąc.",
  "¿Iniciar o cambiar las pólizas presupuestadas? Las primas se cobran cada mes.",
  "Avviare o modificare le polizze del preventivo? I premi vengono addebitati ogni mese.",
  "De geoffreerde polissen starten of wijzigen? De premies worden elke maand afgeschreven.")
t("tp_ins_cancel_sent", "Cancel request sent.", "Kündigung gesendet.", "Demande de résiliation envoyée.", "Wysłano wypowiedzenie.",
  "Cancelación enviada.", "Richiesta di disdetta inviata.", "Opzegging verzonden.")
t("tp_confirm_ins_cancel_crop", "Cancel your crop policy? Open claims are still handled.",
  "Ernteversicherung kündigen? Offene Schadensfälle werden noch bearbeitet.",
  "Résilier votre contrat récolte ? Les sinistres en cours sont encore traités.",
  "Wypowiedzieć polisę upraw? Otwarte szkody są nadal rozpatrywane.",
  "¿Cancelar tu póliza de cosecha? Los siniestros abiertos se siguen tramitando.",
  "Disdire la polizza raccolto? I sinistri aperti vengono ancora gestiti.",
  "Je oogstpolis opzeggen? Openstaande schades worden nog afgehandeld.")
t("tp_confirm_ins_cancel_equip", "Cancel your equipment policy? Open claims are still handled.",
  "Geräteversicherung kündigen? Offene Schadensfälle werden noch bearbeitet.",
  "Résilier votre assurance matériel ? Les sinistres en cours sont encore traités.",
  "Wypowiedzieć polisę sprzętu? Otwarte szkody są nadal rozpatrywane.",
  "¿Cancelar tu seguro de equipos? Los siniestros abiertos se siguen tramitando.",
  "Disdire l'assicurazione mezzi? I sinistri aperti vengono ancora gestiti.",
  "Je materieelverzekering opzeggen? Openstaande schades worden nog afgehandeld.")
t("tp_confirm_ins_cancel_livestock", "Cancel your livestock policy? Open claims are still handled.",
  "Tierversicherung kündigen? Offene Schadensfälle werden noch bearbeitet.",
  "Résilier votre assurance bétail ? Les sinistres en cours sont encore traités.",
  "Wypowiedzieć polisę zwierząt? Otwarte szkody są nadal rozpatrywane.",
  "¿Cancelar tu seguro de ganado? Los siniestros abiertos se siguen tramitando.",
  "Disdire l'assicurazione bestiame? I sinistri aperti vengono ancora gestiti.",
  "Je veeverzekering opzeggen? Openstaande schades worden nog afgehandeld.")
t("tp_ins_note_off", "Insurance is switched off - the server admin can turn it on in the Modules tab.",
  "Die Versicherung ist ausgeschaltet - der Server-Admin kann sie im Reiter Module einschalten.",
  "L'assurance est désactivée - l'admin du serveur peut l'activer dans l'onglet Modules.",
  "Ubezpieczenia są wyłączone - administrator serwera może je włączyć w karcie Moduły.",
  "El seguro está desactivado - el administrador del servidor puede activarlo en la pestaña Módulos.",
  "L'assicurazione è disattivata - l'admin del server può attivarla nella scheda Moduli.",
  "Verzekering staat uit - de serverbeheerder kan haar aanzetten op het tabblad Modules.")
t("tp_ins_note_admin", "Only the server admin may buy or cancel policies - you can still look at quotes.",
  "Nur der Server-Admin darf Policen kaufen oder kündigen - Angebote kannst du trotzdem ansehen.",
  "Seul l'admin du serveur peut souscrire ou résilier - vous pouvez quand même voir les devis.",
  "Tylko administrator serwera może kupować lub wypowiadać polisy - wyceny możesz oglądać.",
  "Solo el administrador puede contratar o cancelar pólizas - aun así puedes ver presupuestos.",
  "Solo l'admin del server può stipulare o disdire polizze - puoi comunque vedere i preventivi.",
  "Alleen de serverbeheerder mag polissen afsluiten of opzeggen - offertes kun je wel bekijken.")
t("tp_ins_note_manager", "Only farm managers and the admin may buy or cancel policies - you can still look at quotes.",
  "Nur Hofmanager und der Admin dürfen Policen kaufen oder kündigen - Angebote kannst du trotzdem ansehen.",
  "Seuls les gérants de la ferme et l'admin peuvent souscrire ou résilier - vous pouvez quand même voir les devis.",
  "Tylko kierownicy gospodarstwa i administrator mogą kupować lub wypowiadać polisy - wyceny możesz oglądać.",
  "Solo los gerentes de la granja y el administrador pueden contratar o cancelar - aun así puedes ver presupuestos.",
  "Solo i gestori della fattoria e l'admin possono stipulare o disdire - puoi comunque vedere i preventivi.",
  "Alleen boerderijbeheerders en de beheerder mogen polissen afsluiten of opzeggen - offertes kun je wel bekijken.")
t("tp_ins_note_crop_off", "Crop insurance is not offered in this region yet (data permission pending).",
  "Ernteversicherung wird in dieser Region noch nicht angeboten (Datenfreigabe ausstehend).",
  "L'assurance récolte n'est pas encore proposée dans cette région (autorisation des données en attente).",
  "Ubezpieczenie upraw nie jest jeszcze oferowane w tym regionie (czekamy na zgodę na dane).",
  "El seguro de cosecha aún no se ofrece en esta región (permiso de datos pendiente).",
  "L'assicurazione raccolto non è ancora offerta in questa regione (autorizzazione dei dati in attesa).",
  "Oogstverzekering wordt in deze regio nog niet aangeboden (toestemming voor de gegevens volgt).")
t("tp_ins_note_crop_none", "Crop insurance: this region's data has no plans.", "Ernteversicherung: die Daten dieser Region haben keine Pläne.",
  "Assurance récolte : les données de cette région n'ont aucun plan.", "Ubezpieczenie upraw: dane tego regionu nie mają planów.",
  "Seguro de cosecha: los datos de esta región no tienen planes.", "Assicurazione raccolto: i dati di questa regione non hanno piani.",
  "Oogstverzekering: de gegevens van deze regio hebben geen plannen.")
t("tp_ins_pol_crop", "%s at %d %% - %s. %d fields, insured value %s, about %s per month.",
  "%s mit %d %% - %s. %d Felder, Versicherungssumme %s, etwa %s pro Monat.",
  "%s à %d %% - %s. %d champs, valeur assurée %s, environ %s par mois.",
  "%s, %d %% - %s. %d pól, suma ubezpieczenia %s, ok. %s miesięcznie.",
  "%s al %d %% - %s. %d campos, valor asegurado %s, unos %s al mes.",
  "%s al %d %% - %s. %d campi, valore assicurato %s, circa %s al mese.",
  "%s op %d %% - %s. %d velden, verzekerde waarde %s, ongeveer %s per maand.")
t("tp_ins_pol_crop_none", "No crop policy.", "Keine Ernteversicherung.", "Pas de contrat récolte.", "Brak polisy upraw.",
  "Sin póliza de cosecha.", "Nessuna polizza raccolto.", "Geen oogstpolis.")
t("tp_ins_pol_equip", "%s deductible - %s. %d vehicles worth %s, about %s per month.",
  "%s Selbstbeteiligung - %s. %d Fahrzeuge im Wert von %s, etwa %s pro Monat.",
  "Franchise %s - %s. %d véhicules d'une valeur de %s, environ %s par mois.",
  "Udział własny %s - %s. %d pojazdów o wartości %s, ok. %s miesięcznie.",
  "Franquicia %s - %s. %d vehículos por valor de %s, unos %s al mes.",
  "Franchigia %s - %s. %d veicoli del valore di %s, circa %s al mese.",
  "%s eigen risico - %s. %d voertuigen ter waarde van %s, ongeveer %s per maand.")
t("tp_ins_pol_equip_none", "No equipment policy.", "Keine Geräteversicherung.", "Pas d'assurance matériel.",
  "Brak ubezpieczenia sprzętu.", "Sin seguro de equipos.", "Nessuna assicurazione mezzi.", "Geen materieelverzekering.")
t("tp_ins_pol_livestock", "All animals - %s. %d animals worth %s, about %s per month.",
  "Alle Tiere - %s. %d Tiere im Wert von %s, etwa %s pro Monat.",
  "Tous les animaux - %s. %d animaux d'une valeur de %s, environ %s par mois.",
  "Wszystkie zwierzęta - %s. %d zwierząt o wartości %s, ok. %s miesięcznie.",
  "Todos los animales - %s. %d animales por valor de %s, unos %s al mes.",
  "Tutti gli animali - %s. %d animali del valore di %s, circa %s al mese.",
  "Alle dieren - %s. %d dieren ter waarde van %s, ongeveer %s per maand.")
t("tp_ins_pol_livestock_none", "No livestock policy.", "Keine Tierversicherung.", "Pas d'assurance bétail.",
  "Brak ubezpieczenia zwierząt.", "Sin seguro de ganado.", "Nessuna assicurazione bestiame.", "Geen veeverzekering.")
t("tp_ins_pol_claims", "Open claims: %d (their letters are on the Messages tab).", "Offene Schadensfälle: %d (die Briefe stehen im Reiter Nachrichten).",
  "Sinistres en cours : %d (leurs lettres sont dans l'onglet Messages).", "Otwarte szkody: %d (listy są w karcie Wiadomości).",
  "Siniestros abiertos: %d (sus cartas están en la pestaña Mensajes).", "Sinistri aperti: %d (le lettere sono nella scheda Messaggi).",
  "Openstaande schades: %d (de brieven staan op het tabblad Berichten).")
t("tp_ins_grows", "Your policies grow with your farm: fields, vehicles and animals you buy later are covered automatically, and the monthly price follows what you own - no need to buy again.",
  "Deine Policen wachsen mit deinem Hof: später gekaufte Felder, Fahrzeuge und Tiere sind automatisch versichert, und der Monatspreis richtet sich nach deinem Besitz - kein erneuter Kauf nötig.",
  "Vos contrats grandissent avec votre ferme : les champs, véhicules et animaux achetés plus tard sont couverts automatiquement, et le prix mensuel suit ce que vous possédez - inutile de racheter.",
  "Twoje polisy rosną razem z gospodarstwem: pola, pojazdy i zwierzęta kupione później są objęte ochroną automatycznie, a miesięczna cena zależy od tego, co posiadasz - nie trzeba kupować ponownie.",
  "Tus pólizas crecen con tu granja: los campos, vehículos y animales que compres después quedan cubiertos automáticamente, y el precio mensual sigue lo que posees - no hace falta volver a contratar.",
  "Le tue polizze crescono con la tua fattoria: campi, veicoli e animali acquistati in seguito sono coperti automaticamente e il prezzo mensile segue ciò che possiedi - non serve riacquistare.",
  "Je polissen groeien mee met je boerderij: velden, voertuigen en dieren die je later koopt zijn automatisch gedekt, en de maandprijs volgt wat je bezit - opnieuw afsluiten is niet nodig.")
t("tp_ins_nav_claims", "Claims", "Schadensfälle", "Sinistres", "Szkody", "Siniestros", "Sinistri", "Claims")
t("tp_ins_cl_title", "Your claims", "Deine Schadensfälle", "Vos sinistres", "Twoje szkody", "Tus siniestros", "I tuoi sinistri", "Je claims")
t("tp_ins_cl_filter", "Show", "Anzeigen", "Afficher", "Pokaż", "Mostrar", "Mostra", "Toon")
t("tp_ins_cl_f_all", "All", "Alle", "Tous", "Wszystkie", "Todos", "Tutti", "Alle")
t("tp_ins_cl_f_open", "Open", "Offen", "En cours", "Otwarte", "Abiertos", "Aperti", "Open")
t("tp_ins_cl_type_crop", "Crop", "Ernte", "Récolte", "Uprawy", "Cosecha", "Raccolto", "Oogst")
t("tp_ins_cl_type_equip", "Equipment", "Geräte", "Matériel", "Sprzęt", "Equipos", "Mezzi", "Materieel")
t("tp_ins_cl_type_livestock", "Livestock", "Tiere", "Bétail", "Zwierzęta", "Ganado", "Bestiame", "Vee")
t("tp_ins_cl_col_day", "Day", "Tag", "Jour", "Dzień", "Día", "Giorno", "Dag")
t("tp_ins_cl_col_type", "Type", "Art", "Type", "Rodzaj", "Tipo", "Tipo", "Soort")
t("tp_ins_cl_col_subject", "What", "Was", "Quoi", "Co", "Qué", "Cosa", "Wat")
t("tp_ins_cl_col_status", "Status", "Status", "État", "Status", "Estado", "Stato", "Status")
t("tp_ins_cl_col_amount", "Payout", "Auszahlung", "Indemnité", "Wypłata", "Pago", "Rimborso", "Uitkering")
t("tp_ins_cl_field", "Field %s", "Feld %s", "Champ %s", "Pole %s", "Campo %s", "Campo %s", "Veld %s")
t("tp_ins_cs_received", "Filed", "Gemeldet", "Déclaré", "Zgłoszona", "Presentado", "Denunciato", "Gemeld")
t("tp_ins_cs_inspected", "Inspected", "Begutachtet", "Expertisé", "Oceniona", "Peritado", "Periziato", "Beoordeeld")
t("tp_ins_cs_approved", "Approved", "Genehmigt", "Accepté", "Uznana", "Aprobado", "Approvato", "Goedgekeurd")
t("tp_ins_cs_paid", "Paid", "Bezahlt", "Payé", "Wypłacona", "Pagado", "Pagato", "Uitbetaald")
t("tp_ins_cs_denied", "Declined", "Abgelehnt", "Refusé", "Odrzucona", "Rechazado", "Respinto", "Afgewezen")
t("tp_ins_cs_total", "Total loss", "Totalschaden", "Perte totale", "Szkoda całkowita", "Siniestro total", "Danno totale", "Total loss")
t("tp_ins_cs_settled", "Settled", "Abgewickelt", "Réglé", "Rozliczona", "Liquidado", "Liquidato", "Afgehandeld")
t("tp_ins_cs_bought_back", "Bought back", "Zurückgekauft", "Racheté", "Odkupiona", "Recomprado", "Riacquistato", "Teruggekocht")
t("tp_ins_cl_selected", "Selected claim", "Ausgewählter Schadensfall", "Sinistre sélectionné", "Wybrana szkoda", "Siniestro seleccionado", "Sinistro selezionato", "Gekozen claim")
t("tp_ins_cl_crop_body", "Field %s, %s. Cause: %s. Crop lost in this event: %d percent.", "Feld %s, %s. Ursache: %s. Ernteverlust bei diesem Ereignis: %d Prozent.", "Champ %s, %s. Cause : %s. Récolte perdue lors de cet événement : %d pour cent.", "Pole %s, %s. Przyczyna: %s. Utracone plony w tym zdarzeniu: %d procent.", "Campo %s, %s. Causa: %s. Cosecha perdida en este evento: %d por ciento.", "Campo %s, %s. Causa: %s. Raccolto perso in questo evento: %d per cento.", "Veld %s, %s. Oorzaak: %s. Oogst verloren bij deze gebeurtenis: %d procent.")
t("tp_date_year", "year %d", "Jahr %d", "année %d", "rok %d", "año %d", "anno %d", "jaar %d")
t("tp_ins_cl_payout", "Payout: %s", "Auszahlung: %s", "Indemnité : %s", "Wypłata: %s", "Pago: %s", "Rimborso: %s", "Uitkering: %s")
t("tp_ins_cl_equip_body", "Insured value (what it sells for now): %s. Storm damage estimate: %s (wear from before the storm is not covered). Deductible: %s.", "Versicherungswert (aktueller Verkaufswert): %s. Schätzung Sturmschaden: %s (Verschleiß von vor dem Sturm ist nicht versichert). Selbstbehalt: %s.", "Valeur assurée (prix de vente actuel) : %s. Estimation des dégâts de tempête : %s (l'usure d'avant la tempête n'est pas couverte). Franchise : %s.", "Wartość ubezpieczenia (obecna cena sprzedaży): %s. Szacunek szkód od burzy: %s (zużycie sprzed burzy nie jest objęte). Udział własny: %s.", "Valor asegurado (precio de venta actual): %s. Estimación de daños por tormenta: %s (el desgaste anterior a la tormenta no está cubierto). Franquicia: %s.", "Valore assicurato (prezzo di vendita attuale): %s. Stima danni da tempesta: %s (l'usura precedente alla tempesta non è coperta). Franchigia: %s.", "Verzekerde waarde (huidige verkoopprijs): %s. Schatting stormschade: %s (slijtage van voor de storm is niet gedekt). Eigen risico: %s.")
t("tp_ins_cl_equip_burned", "The vehicle burned - that is always a total loss.", "Das Fahrzeug ist ausgebrannt - das ist immer ein Totalschaden.", "Le véhicule a brûlé - c'est toujours une perte totale.", "Pojazd spłonął - to zawsze szkoda całkowita.", "El vehículo se quemó: siempre es siniestro total.", "Il veicolo è bruciato: è sempre un danno totale.", "Het voertuig is uitgebrand - dat is altijd total loss.")
t("tp_ins_cl_total_choice", "Accept: the insurer pays %s and takes the wreck. Buy back: you get %s and keep it with a Salvage title (lower sell price).", "Annehmen: die Versicherung zahlt %s und nimmt das Wrack. Zurückkaufen: du bekommst %s und behältst es mit Bergungstitel (niedrigerer Verkaufspreis).", "Accepter : l'assureur paie %s et prend l'épave. Racheter : vous recevez %s et la gardez avec un titre d'épave (prix de vente plus bas).", "Przyjmij: ubezpieczyciel płaci %s i zabiera wrak. Odkup: dostajesz %s i zatrzymujesz go z tytułem wraku (niższa cena sprzedaży).", "Aceptar: la aseguradora paga %s y se lleva el siniestro. Recomprar: recibes %s y lo conservas con título de salvamento (precio de venta menor).", "Accetta: l'assicurazione paga %s e prende il relitto. Riacquista: ricevi %s e lo tieni con titolo di recupero (prezzo di vendita più basso).", "Accepteren: de verzekeraar betaalt %s en neemt het wrak. Terugkopen: je krijgt %s en houdt het met een Salvage-titel (lagere verkoopprijs).")
t("tp_ins_cl_total_keep", "Totalled vehicles are kept on this server: accepting pays %s and you keep the vehicle with a Salvage title (lower sell price).", "Totalschäden bleiben auf diesem Server: Annehmen zahlt %s und du behältst das Fahrzeug mit Bergungstitel (niedrigerer Verkaufspreis).", "Les véhicules en perte totale sont conservés sur ce serveur : accepter paie %s et vous gardez le véhicule avec un titre d'épave (prix de vente plus bas).", "Na tym serwerze pojazdy po szkodzie całkowitej zostają: przyjęcie wypłaca %s, a pojazd zostaje z tytułem wraku (niższa cena sprzedaży).", "En este servidor los vehículos siniestrados se conservan: aceptar paga %s y te quedas el vehículo con título de salvamento (precio de venta menor).", "Su questo server i veicoli in danno totale restano: accettare paga %s e tieni il veicolo con titolo di recupero (prezzo di vendita più basso).", "Op deze server blijven total-loss-voertuigen: accepteren betaalt %s en je houdt het voertuig met een Salvage-titel (lagere verkoopprijs).")
t("tp_ins_cl_lv_body", "%d animals killed at %s. Market value: %s.", "%d Tiere getötet bei %s. Marktwert: %s.", "%d animaux tués à %s. Valeur marchande : %s.", "%d zwierząt zabitych w %s. Wartość rynkowa: %s.", "%d animales muertos en %s. Valor de mercado: %s.", "%d animali uccisi a %s. Valore di mercato: %s.", "%d dieren gedood bij %s. Marktwaarde: %s.")
t("tp_ins_cl_lv_gov", "State programme (USDA LIP) pays: %s.", "Staatliches Programm (USDA LIP) zahlt: %s.", "Programme public (USDA LIP) : %s.", "Program państwowy (USDA LIP) wypłaca: %s.", "Programa estatal (USDA LIP) paga: %s.", "Programma statale (USDA LIP) paga: %s.", "Overheidsprogramma (USDA LIP) betaalt: %s.")
t("tp_ins_cl_lv_policy", "Insured value: %s. Your policy pays: %s.", "Versicherungswert: %s. Deine Police zahlt: %s.", "Valeur assurée : %s. Votre contrat paie : %s.", "Wartość ubezpieczenia: %s. Twoja polisa wypłaca: %s.", "Valor asegurado: %s. Tu póliza paga: %s.", "Valore assicurato: %s. La tua polizza paga: %s.", "Verzekerde waarde: %s. Je polis betaalt: %s.")
t("tp_ins_cl_next_received", "The adjuster visits in about %d days %d hours.", "Der Gutachter kommt in etwa %d Tagen %d Stunden.", "L'expert passe dans environ %d jours %d heures.", "Rzeczoznawca przyjedzie za ok. %d dni %d godz.", "El perito llega en unos %d días %d horas.", "Il perito arriva tra circa %d giorni %d ore.", "De expert komt over ongeveer %d dagen %d uur.")
t("tp_ins_cl_next_inspected", "Decision in about %d days %d hours.", "Entscheidung in etwa %d Tagen %d Stunden.", "Décision dans environ %d jours %d heures.", "Decyzja za ok. %d dni %d godz.", "Decisión en unos %d días %d horas.", "Decisione tra circa %d giorni %d ore.", "Beslissing over ongeveer %d dagen %d uur.")
t("tp_ins_cl_next_approved", "Payment in about %d days %d hours.", "Zahlung in etwa %d Tagen %d Stunden.", "Paiement dans environ %d jours %d heures.", "Wypłata za ok. %d dni %d godz.", "Pago en unos %d días %d horas.", "Pagamento tra circa %d giorni %d ore.", "Betaling over ongeveer %d dagen %d uur.")
t("tp_ins_cl_next_total", "Choose within %d days %d hours - after that the total loss is accepted for you.", "Entscheide innerhalb von %d Tagen %d Stunden - danach wird der Totalschaden für dich angenommen.", "Choisissez dans les %d jours %d heures - ensuite la perte totale est acceptée pour vous.", "Zdecyduj w ciągu %d dni %d godz. - potem szkoda całkowita zostanie przyjęta za ciebie.", "Elige en %d días %d horas; después se acepta el siniestro total por ti.", "Scegli entro %d giorni %d ore - poi il danno totale viene accettato per te.", "Kies binnen %d dagen %d uur - daarna wordt de total loss voor je geaccepteerd.")
t("tp_ins_cl_denied", "Declined - the letter on the Messages tab says why.", "Abgelehnt - der Brief im Reiter Nachrichten nennt den Grund.", "Refusé - la lettre dans l'onglet Messages en donne la raison.", "Odrzucona - list w zakładce Wiadomości podaje powód.", "Rechazado: la carta de la pestaña Mensajes explica el motivo.", "Respinto - la lettera nella scheda Messaggi spiega il motivo.", "Afgewezen - de brief op het tabblad Berichten zegt waarom.")
t("tp_ins_cl_done", "Closed - the money was paid to the farm.", "Abgeschlossen - das Geld wurde an den Hof gezahlt.", "Clos - l'argent a été versé à la ferme.", "Zamknięta - pieniądze wpłacono gospodarstwu.", "Cerrado: el dinero se pagó a la granja.", "Chiuso - il denaro è stato pagato alla fattoria.", "Gesloten - het geld is aan de boerderij betaald.")
t("tp_ins_cl_hidden", "No claims match this filter (%d hidden).", "Keine Schadensfälle für diesen Filter (%d ausgeblendet).", "Aucun sinistre pour ce filtre (%d masqués).", "Brak szkód dla tego filtra (%d ukrytych).", "Ningún siniestro con este filtro (%d ocultos).", "Nessun sinistro con questo filtro (%d nascosti).", "Geen claims voor dit filter (%d verborgen).")
t("tp_ins_cl_none", "No claims yet. When a storm damages something insured, the claim shows up here.", "Noch keine Schadensfälle. Wenn ein Sturm etwas Versichertes beschädigt, erscheint der Fall hier.", "Aucun sinistre pour l'instant. Quand une tempête endommage un bien assuré, le sinistre apparaît ici.", "Brak szkód. Gdy burza uszkodzi coś ubezpieczonego, szkoda pojawi się tutaj.", "Aún no hay siniestros. Cuando una tormenta dañe algo asegurado, el siniestro aparecerá aquí.", "Ancora nessun sinistro. Quando una tempesta danneggia qualcosa di assicurato, il sinistro compare qui.", "Nog geen claims. Als een storm iets verzekerds beschadigt, verschijnt de claim hier.")
t("tp_ins_choice_sent", "Choice sent - the letter follows on the Messages tab.", "Entscheidung gesendet - der Brief folgt im Reiter Nachrichten.", "Choix envoyé - la lettre suit dans l'onglet Messages.", "Wybór wysłany - list pojawi się w zakładce Wiadomości.", "Elección enviada: la carta llegará a la pestaña Mensajes.", "Scelta inviata - la lettera segue nella scheda Messaggi.", "Keuze verzonden - de brief volgt op het tabblad Berichten.")
t("tp_btn_ins_accept_total", "Accept total loss", "Totalschaden annehmen", "Accepter la perte totale", "Przyjmij szkodę całkowitą", "Aceptar siniestro total", "Accetta danno totale", "Total loss accepteren")
t("tp_btn_ins_buy_back", "Buy back", "Zurückkaufen", "Racheter", "Odkup", "Recomprar", "Riacquista", "Terugkopen")
t("tp_ins_nav_payments", "Payments", "Zahlungen", "Paiements", "Płatności", "Pagos", "Pagamenti", "Betalingen")
t("tp_ins_nav_info", "Coverage info", "Schutz-Infos", "Infos couverture", "Informacje o ochronie", "Info de cobertura", "Info copertura", "Dekkingsinfo")
t("tp_ins_pay_title", "Monthly history", "Monatsverlauf", "Historique mensuel", "Historia miesięczna", "Historial mensual", "Storico mensile", "Maandoverzicht")
t("tp_ins_pay_col_month", "Month", "Monat", "Mois", "Miesiąc", "Mes", "Mese", "Maand")
t("tp_ins_pay_col_premiums", "Premiums", "Beiträge", "Primes", "Składki", "Primas", "Premi", "Premies")
t("tp_ins_pay_col_payouts", "Payouts", "Auszahlungen", "Indemnités", "Wypłaty", "Pagos", "Rimborsi", "Uitkeringen")
t("tp_ins_pay_col_net", "Net", "Saldo", "Solde", "Saldo", "Saldo", "Saldo", "Saldo")
t("tp_ins_pay_totals", "Totals", "Summen", "Totaux", "Podsumowanie", "Totales", "Totali", "Totalen")
t("tp_ins_pay_selected", "Selected month", "Ausgewählter Monat", "Mois sélectionné", "Wybrany miesiąc", "Mes seleccionado", "Mese selezionato", "Gekozen maand")
t("tp_ins_pay_state", "State programme", "Staatliches Programm", "Programme public", "Program państwowy", "Programa estatal", "Programma statale", "Overheidsprogramma")
t("tp_ins_pay_other", "Other", "Sonstiges", "Autre", "Inne", "Otros", "Altro", "Overig")
t("tp_ins_pay_premiums_total", "Premiums paid so far: %s", "Bisher gezahlte Beiträge: %s", "Primes payées jusqu'ici : %s", "Dotychczas zapłacone składki: %s", "Primas pagadas hasta ahora: %s", "Premi pagati finora: %s", "Tot nu toe betaalde premies: %s")
t("tp_ins_pay_payouts_total", "Payouts received so far: %s", "Bisher erhaltene Auszahlungen: %s", "Indemnités reçues jusqu'ici : %s", "Dotychczas otrzymane wypłaty: %s", "Pagos recibidos hasta ahora: %s", "Rimborsi ricevuti finora: %s", "Tot nu toe ontvangen uitkeringen: %s")
t("tp_ins_pay_balance_plus", "The insurance has paid you %s more than it cost.", "Die Versicherung hat dir %s mehr gezahlt, als sie gekostet hat.", "L'assurance vous a versé %s de plus qu'elle n'a coûté.", "Ubezpieczenie wypłaciło ci o %s więcej, niż kosztowało.", "El seguro te ha pagado %s más de lo que ha costado.", "L'assicurazione ti ha pagato %s più di quanto è costata.", "De verzekering heeft je %s meer uitgekeerd dan ze kostte.")
t("tp_ins_pay_balance_minus", "So far the insurance has cost %s more than it paid out.", "Bisher hat die Versicherung %s mehr gekostet, als sie ausgezahlt hat.", "Jusqu'ici l'assurance a coûté %s de plus qu'elle n'a versé.", "Jak dotąd ubezpieczenie kosztowało o %s więcej, niż wypłaciło.", "Hasta ahora el seguro ha costado %s más de lo que ha pagado.", "Finora l'assicurazione è costata %s più di quanto ha pagato.", "Tot nu toe kostte de verzekering %s meer dan ze uitkeerde.")
t("tp_ins_pay_next", "Next bill at the month change: about %s (%s).", "Nächste Rechnung beim Monatswechsel: etwa %s (%s).", "Prochaine facture au changement de mois : environ %s (%s).", "Następny rachunek przy zmianie miesiąca: ok. %s (%s).", "Próxima factura al cambiar de mes: unos %s (%s).", "Prossima fattura al cambio di mese: circa %s (%s).", "Volgende rekening bij de maandwissel: ongeveer %s (%s).")
t("tp_ins_pay_next_none", "Next bill: nothing - no policy is active.", "Nächste Rechnung: nichts - keine Police ist aktiv.", "Prochaine facture : rien - aucun contrat n'est actif.", "Następny rachunek: brak - żadna polisa nie jest aktywna.", "Próxima factura: nada, ninguna póliza está activa.", "Prossima fattura: niente - nessuna polizza è attiva.", "Volgende rekening: niets - geen polis is actief.")
t("tp_ins_pay_pending", "Policies still in their waiting time are billed once they start.", "Policen in der Wartezeit werden erst ab ihrem Beginn berechnet.", "Les contrats encore en délai d'attente sont facturés dès qu'ils commencent.", "Polisy w okresie karencji są naliczane dopiero od ich rozpoczęcia.", "Las pólizas aún en periodo de espera se facturan cuando empiezan.", "Le polizze ancora in periodo di attesa si pagano da quando iniziano.", "Polissen in hun wachttijd worden pas gerekend zodra ze ingaan.")
t("tp_ins_pay_month_premiums", "Premiums: %s", "Beiträge: %s", "Primes : %s", "Składki: %s", "Primas: %s", "Premi: %s", "Premies: %s")
t("tp_ins_pay_month_payouts", "Payouts: %s", "Auszahlungen: %s", "Indemnités : %s", "Wypłaty: %s", "Pagos: %s", "Rimborsi: %s", "Uitkeringen: %s")
t("tp_ins_pay_none", "No payments yet.", "Noch keine Zahlungen.", "Aucun paiement pour l'instant.", "Brak płatności.", "Aún no hay pagos.", "Ancora nessun pagamento.", "Nog geen betalingen.")
t("tp_ins_info_title", "How your insurance works", "So funktioniert deine Versicherung", "Comment fonctionne votre assurance", "Jak działa twoje ubezpieczenie", "Cómo funciona tu seguro", "Come funziona la tua assicurazione", "Zo werkt je verzekering")
t("tp_ins_info_region", "Rules and prices of: %s.", "Regeln und Preise von: %s.", "Règles et prix de : %s.", "Zasady i ceny: %s.", "Reglas y precios de: %s.", "Regole e prezzi di: %s.", "Regels en prijzen van: %s.")
t("tp_ins_info_crop", "Crop: covers every field the farm owns with an insurable crop. Plans here: %s. Coverage %d - %d percent of the expected harvest value. Buying or changing a crop policy: %s.", "Ernte: deckt jedes Feld des Hofs mit einer versicherbaren Frucht. Pläne hier: %s. Deckung %d - %d Prozent des erwarteten Erntewerts. Kauf oder Änderung einer Erntepolice: %s.", "Récolte : couvre chaque champ de la ferme avec une culture assurable. Formules ici : %s. Couverture %d - %d pour cent de la valeur de récolte attendue. Souscrire ou modifier un contrat récolte : %s.", "Uprawy: obejmuje każde pole gospodarstwa z ubezpieczalną uprawą. Plany tutaj: %s. Ochrona %d - %d procent oczekiwanej wartości zbiorów. Zakup lub zmiana polisy: %s.", "Cosecha: cubre cada campo de la granja con un cultivo asegurable. Planes aquí: %s. Cobertura del %d al %d por ciento del valor esperado de la cosecha. Contratar o cambiar una póliza de cosecha: %s.", "Raccolto: copre ogni campo della fattoria con una coltura assicurabile. Piani qui: %s. Copertura %d - %d per cento del valore atteso del raccolto. Acquisto o modifica di una polizza raccolto: %s.", "Oogst: dekt elk veld van de boerderij met een verzekerbaar gewas. Plannen hier: %s. Dekking %d - %d procent van de verwachte oogstwaarde. Een oogstpolis afsluiten of wijzigen: %s.")
t("tp_ins_info_sales_open", "possible now", "jetzt möglich", "possible maintenant", "możliwe teraz", "posible ahora", "possibile ora", "nu mogelijk")
t("tp_ins_info_sales_closed", "only in %s (closed now)", "nur im %s (jetzt geschlossen)", "seulement en %s (fermé maintenant)", "tylko w: %s (teraz zamknięte)", "solo en %s (cerrado ahora)", "solo a %s (ora chiuso)", "alleen in %s (nu gesloten)")
t("tp_ins_info_equip", "Equipment: every vehicle the farm owns, valued at %s. Price a year, as a share of that value, by deductible: %s. %d percent damage or a burned vehicle is a total loss.", "Geräte: jedes Fahrzeug des Hofs, bewertet mit %s. Preis pro Jahr als Anteil dieses Werts, je nach Selbstbehalt: %s. Ab %d Prozent Schaden oder bei einem ausgebrannten Fahrzeug ist es ein Totalschaden.", "Matériel : chaque véhicule de la ferme, évalué à %s. Prix par an, en part de cette valeur, selon la franchise : %s. %d pour cent de dégâts ou un véhicule brûlé, c'est une perte totale.", "Sprzęt: każdy pojazd gospodarstwa, wyceniony jako %s. Cena za rok jako część tej wartości, wg udziału własnego: %s. %d procent uszkodzeń lub spalony pojazd to szkoda całkowita.", "Equipos: cada vehículo de la granja, valorado en %s. Precio al año, como parte de ese valor, según la franquicia: %s. Un %d por ciento de daño o un vehículo quemado es siniestro total.", "Mezzi: ogni veicolo della fattoria, valutato %s. Prezzo all'anno, come quota di quel valore, per franchigia: %s. Il %d per cento di danno o un veicolo bruciato è un danno totale.", "Materieel: elk voertuig van de boerderij, gewaardeerd op %s. Prijs per jaar als deel van die waarde, per eigen risico: %s. %d procent schade of een uitgebrand voertuig is total loss.")
t("tp_ins_info_value_sell", "what it sells for now", "seinem aktuellen Verkaufswert", "son prix de vente actuel", "obecna cena sprzedaży", "su precio de venta actual", "il suo prezzo di vendita attuale", "wat het nu opbrengt")
t("tp_ins_info_value_replacement", "what it sells for now plus 15 percent (replacement value)", "seinem aktuellen Verkaufswert plus 15 Prozent (Wiederbeschaffungswert)", "son prix de vente actuel plus 15 pour cent (valeur de remplacement)", "obecna cena sprzedaży plus 15 procent (wartość odtworzeniowa)", "su precio de venta actual más un 15 por ciento (valor de reposición)", "il suo prezzo di vendita attuale più il 15 per cento (valore di rimpiazzo)", "wat het nu opbrengt plus 15 procent (vervangingswaarde)")
t("tp_ins_info_rate", "%s: %s percent", "%s: %s Prozent", "%s : %s pour cent", "%s: %s procent", "%s: %s por ciento", "%s: %s per cento", "%s: %s procent")
t("tp_ins_info_total", "Total loss: accept (the insurer pays the value minus the deductible and takes the vehicle) or buy back (you keep it with a Salvage title, sell price -%d percent; repaired it becomes Rebuilt, -%d percent). Wear from before the storm is not covered.", "Totalschaden: annehmen (die Versicherung zahlt den Wert minus Selbstbehalt und nimmt das Fahrzeug) oder zurückkaufen (du behältst es mit Bergungstitel, Verkaufspreis -%d Prozent; repariert wird es Wiederaufgebaut, -%d Prozent). Verschleiß von vor dem Sturm ist nicht versichert.", "Perte totale : accepter (l'assureur paie la valeur moins la franchise et prend le véhicule) ou racheter (vous le gardez avec un titre d'épave, prix de vente -%d pour cent ; réparé il devient Reconstruit, -%d pour cent). L'usure d'avant la tempête n'est pas couverte.", "Szkoda całkowita: przyjmij (ubezpieczyciel płaci wartość minus udział własny i zabiera pojazd) albo odkup (zatrzymujesz go z tytułem wraku, cena sprzedaży -%d procent; po naprawie staje się Odbudowany, -%d procent). Zużycie sprzed burzy nie jest objęte.", "Siniestro total: aceptar (la aseguradora paga el valor menos la franquicia y se lleva el vehículo) o recomprar (te lo quedas con título de salvamento, precio de venta -%d por ciento; reparado pasa a Reconstruido, -%d por ciento). El desgaste anterior a la tormenta no está cubierto.", "Danno totale: accetta (l'assicurazione paga il valore meno la franchigia e prende il veicolo) o riacquista (lo tieni con titolo di recupero, prezzo di vendita -%d per cento; riparato diventa Ricostruito, -%d per cento). L'usura precedente alla tempesta non è coperta.", "Total loss: accepteren (de verzekeraar betaalt de waarde min het eigen risico en neemt het voertuig) of terugkopen (je houdt het met een Salvage-titel, verkoopprijs -%d procent; gerepareerd wordt het Rebuilt, -%d procent). Slijtage van voor de storm is niet gedekt.")
t("tp_ins_info_total_keep", "Total loss: totalled vehicles are kept on this server - you get the value minus the deductible and the salvage value and keep the vehicle with a Salvage title (sell price -%d percent; repaired Rebuilt, -%d percent). Wear from before the storm is not covered.", "Totalschaden: auf diesem Server bleiben Totalschäden beim Hof - du bekommst den Wert minus Selbstbehalt und Restwert und behältst das Fahrzeug mit Bergungstitel (Verkaufspreis -%d Prozent; repariert Wiederaufgebaut, -%d Prozent). Verschleiß von vor dem Sturm ist nicht versichert.", "Perte totale : sur ce serveur les véhicules restent à la ferme - vous recevez la valeur moins la franchise et la valeur d'épave et gardez le véhicule avec un titre d'épave (prix de vente -%d pour cent ; réparé Reconstruit, -%d pour cent). L'usure d'avant la tempête n'est pas couverte.", "Szkoda całkowita: na tym serwerze pojazdy zostają w gospodarstwie - dostajesz wartość minus udział własny i wartość wraku, a pojazd zostaje z tytułem wraku (cena sprzedaży -%d procent; po naprawie Odbudowany, -%d procent). Zużycie sprzed burzy nie jest objęte.", "Siniestro total: en este servidor los vehículos se quedan en la granja; recibes el valor menos la franquicia y el valor de salvamento y te quedas el vehículo con título de salvamento (precio de venta -%d por ciento; reparado Reconstruido, -%d por ciento). El desgaste anterior a la tormenta no está cubierto.", "Danno totale: su questo server i veicoli restano alla fattoria - ricevi il valore meno la franchigia e il valore di recupero e tieni il veicolo con titolo di recupero (prezzo di vendita -%d per cento; riparato Ricostruito, -%d per cento). L'usura precedente alla tempesta non è coperta.", "Total loss: op deze server blijven voertuigen op de boerderij - je krijgt de waarde min het eigen risico en de restwaarde en houdt het voertuig met een Salvage-titel (verkoopprijs -%d procent; gerepareerd Rebuilt, -%d procent). Slijtage van voor de storm is niet gedekt.")
t("tp_ins_info_livestock", "Livestock: every animal in the farm's pastures, valued at its sell price. About %s percent a year of the herd value; %d percent excess on every claim.", "Tiere: jedes Tier auf den Weiden des Hofs, bewertet mit seinem Verkaufspreis. Etwa %s Prozent des Herdenwerts pro Jahr; %d Prozent Selbstbehalt bei jedem Schaden.", "Bétail : chaque animal des pâtures de la ferme, évalué à son prix de vente. Environ %s pour cent par an de la valeur du troupeau ; %d pour cent de franchise sur chaque sinistre.", "Zwierzęta: każde zwierzę na pastwiskach gospodarstwa, wycenione wg ceny sprzedaży. Ok. %s procent wartości stada rocznie; %d procent udziału własnego przy każdej szkodzie.", "Ganado: cada animal de los pastos de la granja, valorado a su precio de venta. Alrededor del %s por ciento al año del valor del rebaño; %d por ciento de franquicia en cada siniestro.", "Bestiame: ogni animale nei pascoli della fattoria, valutato al prezzo di vendita. Circa il %s per cento all'anno del valore della mandria; %d per cento di franchigia su ogni sinistro.", "Vee: elk dier in de weides van de boerderij, gewaardeerd op de verkoopprijs. Ongeveer %s procent per jaar van de waarde van de kudde; %d procent eigen risico per claim.")
t("tp_ins_info_livestock_gov", "On this map the USDA Livestock Indemnity Program pays %d percent of the market value for free (also without a policy); a policy pays the rest.", "Auf dieser Karte zahlt das USDA Livestock Indemnity Program kostenlos %d Prozent des Marktwerts (auch ohne Police); eine Police zahlt den Rest.", "Sur cette carte le USDA Livestock Indemnity Program paie gratuitement %d pour cent de la valeur marchande (même sans contrat) ; un contrat paie le reste.", "Na tej mapie program USDA Livestock Indemnity Program bezpłatnie wypłaca %d procent wartości rynkowej (także bez polisy); polisa pokrywa resztę.", "En este mapa el USDA Livestock Indemnity Program paga gratis el %d por ciento del valor de mercado (también sin póliza); una póliza paga el resto.", "Su questa mappa lo USDA Livestock Indemnity Program paga gratis il %d per cento del valore di mercato (anche senza polizza); una polizza paga il resto.", "Op deze kaart betaalt het USDA Livestock Indemnity Program gratis %d procent van de marktwaarde (ook zonder polis); een polis betaalt de rest.")
t("tp_ins_info_timing", "Timing (counted in real-life days, 30 = one game month; here %d days per month): new cover starts after %s; after a claim the adjuster comes in %s, the decision follows %s later and the payment %s after that. A total loss not decided within %s is accepted for you.", "Zeiten (in realen Tagen, 30 = ein Spielmonat; hier %d Tage pro Monat): neuer Schutz beginnt nach %s; nach einer Schadensmeldung kommt der Gutachter in %s, die Entscheidung folgt %s später und die Zahlung %s danach. Ein Totalschaden ohne Entscheidung innerhalb von %s wird für dich angenommen.", "Délais (en jours réels, 30 = un mois de jeu ; ici %d jours par mois) : une nouvelle couverture commence après %s ; après un sinistre l'expert vient dans %s, la décision suit %s plus tard et le paiement %s après. Une perte totale non décidée dans les %s est acceptée pour vous.", "Czas (w dniach rzeczywistych, 30 = jeden miesiąc gry; tutaj %d dni na miesiąc): nowa ochrona zaczyna się po %s; po zgłoszeniu rzeczoznawca przyjeżdża za %s, decyzja zapada %s później, a wypłata %s po niej. Szkoda całkowita bez decyzji w ciągu %s zostaje przyjęta za ciebie.", "Plazos (en días reales, 30 = un mes de juego; aquí %d días por mes): la nueva cobertura empieza tras %s; tras un siniestro el perito llega en %s, la decisión %s después y el pago %s más tarde. Un siniestro total no decidido en %s se acepta por ti.", "Tempi (in giorni reali, 30 = un mese di gioco; qui %d giorni al mese): la nuova copertura inizia dopo %s; dopo un sinistro il perito arriva in %s, la decisione segue %s dopo e il pagamento %s più tardi. Un danno totale non deciso entro %s viene accettato per te.", "Tijden (in echte dagen, 30 = één spelmaand; hier %d dagen per maand): nieuwe dekking begint na %s; na een claim komt de expert binnen %s, de beslissing volgt %s later en de betaling %s daarna. Een total loss zonder beslissing binnen %s wordt voor je geaccepteerd.")
t("tp_ins_info_duration", "%d d %d h", "%d T %d Std", "%d j %d h", "%d d %d godz.", "%d d %d h", "%d g %d h", "%d d %d u")
t("tp_ins_info_billing", "Premiums are billed at every month change, from what the farm owns then.", "Beiträge werden bei jedem Monatswechsel berechnet, nach dem, was der Hof dann besitzt.", "Les primes sont facturées à chaque changement de mois, selon ce que la ferme possède alors.", "Składki są naliczane przy każdej zmianie miesiąca, według tego, co gospodarstwo wtedy posiada.", "Las primas se facturan en cada cambio de mes, según lo que la granja posea entonces.", "I premi si pagano a ogni cambio di mese, in base a ciò che la fattoria possiede allora.", "Premies worden bij elke maandwissel gerekend, naar wat de boerderij dan bezit.")
t("tp_ins_info_manage", "Farm managers and the server admin can buy, change and cancel policies and decide total losses; everybody else can look.", "Hofmanager und der Server-Admin können Policen kaufen, ändern, kündigen und über Totalschäden entscheiden; alle anderen können zuschauen.", "Les gérants de ferme et l'admin du serveur peuvent souscrire, modifier, résilier les contrats et décider des pertes totales ; les autres peuvent consulter.", "Zarządcy gospodarstwa i admin serwera mogą kupować, zmieniać, anulować polisy i decydować o szkodach całkowitych; pozostali mogą tylko patrzeć.", "Los gerentes de la granja y el admin del servidor pueden contratar, cambiar y cancelar pólizas y decidir siniestros totales; los demás pueden mirar.", "I gestori della fattoria e l'admin del server possono acquistare, modificare e annullare polizze e decidere i danni totali; gli altri possono guardare.", "Boerderijbeheerders en de serverbeheerder kunnen polissen afsluiten, wijzigen, opzeggen en over total loss beslissen; de rest kan meekijken.")
t("tp_ins_pol_change_hint", "To change a policy, choose the new cover under Start here and get a quote.",
  "Um eine Police zu ändern, wähle unter Hier starten den neuen Schutz und hole ein Angebot.",
  "Pour modifier un contrat, choisissez la nouvelle couverture dans Commencer ici et demandez un devis.",
  "Aby zmienić polisę, wybierz nową ochronę w Zacznij tutaj i poproś o wycenę.",
  "Para cambiar una póliza, elige la nueva cobertura en Empieza aquí y pide un presupuesto.",
  "Per modificare una polizza, scegli la nuova copertura in Inizia qui e chiedi un preventivo.",
  "Om een polis te wijzigen, kies je de nieuwe dekking onder Begin hier en vraag je een offerte.")

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
