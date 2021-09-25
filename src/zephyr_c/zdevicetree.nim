
import cmtoken
export cmtoken

# template DT_NODELABEL*(label: cminvtoken): cminvtoken = CTOKEN(label)

CM_DECLARE_PROC(DT_NODELABEL, label)

# proc DT_NODELABEL*(node_id: cminvtoken): cminvtoken {.importc: "DT_NODELABEL", header: "devicetree.h".}

