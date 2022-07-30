---
layout: page
title: Moves
permalink: /wiki/moves
---



| Move | Type | Category | Power | Accuracy | PP |
|:--------|:-----|:-----|:-----|:--------|{% for move in site.data.moves %}
| [{{ move.name }}](/wiki/moves/{{ move.key }}) | ![{{ move.type }}](/assets/img/types/{{ move.type }}.png) | ![{{ move.split }}](/assets/img/category/{{ move.split }}.png) | {{ move.power }} | {{ move.accuracy }} | {{ move.pp }} |{% endfor %}