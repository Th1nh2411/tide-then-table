"""Compatibility entry point; surface-fit actual Rin eyes to Bảo."""
from match_character_eyes_to_rin import match as match_character

def match(use_saved_fit=False):
    return match_character('bao', use_saved_fit=use_saved_fit)

if __name__ == '__main__':
    match()
