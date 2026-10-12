# Île Manga V7 — décor village

La V7 enrichit la scène native Godot : clôtures autour des habitations, sentier secondaire, fleurs groupées et balises lumineuses. Les décorations utilisent MultiMesh pour limiter les appels graphiques. Aucune collision ni nouvelle interaction n’est ajoutée, afin de préserver les déplacements VR validés en V5.

Deux sorties Windows : `Ile_Manga_VR_v7.exe` et `Ile_Manga_PC_v7.exe`. La version PC affiche davantage de fleurs et une distance d’affichage plus élevée. Le résultat visuel et la fluidité doivent être vérifiés sur Quest 3 après compilation GitHub.

Correctif du build V6 : le script `set_pc_export.py` ne dépend plus du numéro V5 et fonctionne avec les futures versions.
