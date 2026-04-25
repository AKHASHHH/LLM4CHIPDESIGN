def priority_encoder_3bit_golden(in_signal):
    out = 0
    valid = 0

    if in_signal & 0b100:
        out = 2
        valid = 1
    elif in_signal & 0b010:
        out = 1
        valid = 1
    elif in_signal & 0b001:
        out = 0
        valid = 1
    else:
        out = 0
        valid = 0

    return {'out': out, 'valid': valid}