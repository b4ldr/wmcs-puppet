type Cfssl::Profile = Struct[{
    usages        => Optional[Array[Cfssl::Usage]],
    expiry        => Optional[Cfssl::Expiry],
    ca_constraint => Optional[Cfssl::Ca_constraint],
}]
