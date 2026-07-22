#!/usr/bin/env python3
import json, shutil
CFG = '/home/ph/.config/Element/config.json'
shutil.copy(CFG, CFG + '.mmd.bak')
d = json.load(open(CFG))

# key reference from the existing theme (exact set Element expects)
ref = d['setting_defaults']['custom_themes'][0]['compound']

# --- monochrome ramp (index by Compound stop) -------------------------------
NS = [100,200,300,400,500,600,700,800,900,1000,1100,1200,1300,1400]
RAMP = ['#141414','#1c1c1c','#242424','#2e2e2e','#3a3a3a','#484848','#585858',
        '#6a6a6a','#7e7e7e','#949494','#ababab','#c4c4c4','#dedede','#ffffff']
def ramp(): return {n:c for n,c in zip(NS, RAMP)}
HUES = ('red','orange','yellow','green','blue','purple','cyan','pink','lime','fuchsia')

# --- semantic tokens (explicit) --------------------------------------------
# DARK: bg #000, fg #fff, accent = inverted white
SEM = {
  'theme-bg':'#000000',
  'text-primary':'#ffffff','text-secondary':'#b0b0b0','text-disabled':'#666666',
  'text-action-primary':'#ffffff','text-action-accent':'#ffffff','text-link-external':'#ffffff',
  'text-critical-primary':'#e0e0e0','text-success-primary':'#e0e0e0','text-info-primary':'#e0e0e0',
  'text-on-solid-primary':'#000000',
  'text-decorative-1':'#cccccc','text-decorative-2':'#b0b0b0','text-decorative-3':'#e0e0e0',
  'text-decorative-4':'#999999','text-decorative-5':'#c4c4c4','text-decorative-6':'#a8a8a8',
  'bg-subtle-primary':'#141414','bg-subtle-secondary':'#1a1a1a','bg-subtle-secondary-level-0':'#141414',
  'bg-canvas-default':'#000000','bg-canvas-default-level-1':'#0d0d0d','bg-canvas-disabled':'#0a0a0a',
  'bg-action-primary-disabled':'#333333','bg-action-secondary-rest':'#141414',
  'bg-action-tertiary-rest':'#141414','bg-action-tertiary-hovered':'#1f1f1f','bg-action-tertiary-selected':'#262626',
  'bg-critical-primary':'#b0b0b0','bg-critical-hovered':'#c8c8c8','bg-critical-subtle':'#1a1a1a',
  'bg-success-subtle':'#141414','bg-info-subtle':'#141414',
  'bg-accent-rest':'#ffffff','bg-accent-hovered':'#e0e0e0','bg-accent-pressed':'#c8c8c8','bg-accent-selected':'#2a2a2a',
  'bg-decorative-1':'#141414','bg-decorative-2':'#161616','bg-decorative-3':'#181818',
  'bg-decorative-4':'#1a1a1a','bg-decorative-5':'#121212','bg-decorative-6':'#171717',
  'icon-primary':'#ffffff','icon-secondary':'#b0b0b0','icon-tertiary':'#888888','icon-quaternary':'#666666',
  'icon-accent-primary':'#ffffff','icon-critical-primary':'#b0b0b0','icon-success-primary':'#b0b0b0','icon-info-primary':'#b0b0b0',
  'icon-on-solid-primary':'#000000','icon-disabled':'#555555',
  'border-interactive-primary':'#444444','border-interactive-secondary':'#333333','border-interactive-hovered':'#666666',
  'border-disabled':'#2a2a2a','border-focused':'#ffffff','border-critical-primary':'#888888',
  'border-success-subtle':'#333333','border-info-subtle':'#333333','border-accent-subtle':'#444444',
}

def build_compound():
    gr = ramp(); out = {}
    for k in ref:
        name = k.replace('--cpd-color-', '')
        if name.startswith('gray-') or any(name.startswith(h+'-') for h in HUES):
            stop = int(name.rsplit('-', 1)[1]); out[k] = gr[stop]          # all hues -> grayscale
        else:
            out[k] = SEM.get(name, gr[900])                                # semantic
    return out

LEGACY = {
  'accent-color':'#ffffff','primary-color':'#ffffff','warning-color':'#b0b0b0','alert':'#c8c8c8',
  'sidebar-color':'#000000','roomlist-background-color':'#000000','roomlist-text-color':'#ffffff',
  'roomlist-text-secondary-color':'#b0b0b0','roomlist-highlights-color':'#1a1a1a','roomlist-separator-color':'#444444',
  'timeline-background-color':'#000000','timeline-text-color':'#ffffff','secondary-content':'#b0b0b0','tertiary-content':'#888888',
  'timeline-text-secondary-color':'#b0b0b0','timeline-highlights-color':'#141414',
  'reaction-row-button-selected-bg-color':'#2a2a2a','menu-selected-color':'#1a1a1a','focus-bg-color':'#1a1a1a',
  'room-highlight-color':'#ffffff','togglesw-off-color':'#555555','other-user-pill-bg-color':'#333333',
  'username-colors':['#ffffff','#d0d0d0','#b0b0b0','#c8c8c8','#e0e0e0','#a8a8a8','#bcbcbc','#dcdcdc'],
  'avatar-background-colors':['#333333','#444444','#555555'],
}

def theme():
    return {'name':'MMD Dark','is_dark':True,'colors':LEGACY,'compound':build_compound()}

sd = d['setting_defaults']
themes = [t for t in sd['custom_themes'] if t.get('name') not in ('MMD Dark','MMD Light')]
sd['custom_themes'] = [theme()] + themes
sd['theme'] = 'MMD Dark'          # dark-only: no switcher, force it as default
# humanist UI font (monospace/code stays mono)
sd['useSystemFont'] = True
sd['systemFont'] = 'Lato'

json.dump(d, open(CFG,'w'), indent=2)
json.load(open(CFG))  # re-validate
print('OK. themes now:', [t['name'] for t in sd['custom_themes']])
print('compound keys per MMD theme:', len(theme()['compound']))
