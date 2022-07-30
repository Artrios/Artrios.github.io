---
layout: page
title: Pokedex
---



| Dex No. |      | Species |   |
|:--------|:-----|:--------|:--|{% for pokemon in site.data.basestats %}{% if pokemon.id < 721 %}
| #{{ pokemon.dex_number }} | ![{{ pokemon.name }}](/assets/img/pokemon/icons/{{ pokemon.dex_number }}MS.png) | [{{ pokemon.name }}](/wiki/pokedex/{{ pokemon.name | downcase }}) | ![{{ pokemon.type1 }}](/assets/img/types/{{ pokemon.type1 }}.png) {% if pokemon.type1 != pokemon.type2 %} ![{{ pokemon.type2 }}](/assets/img/types/{{ pokemon.type2 }}.png) {% endif %}|{% endif %}{% endfor %}