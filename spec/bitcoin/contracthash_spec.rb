# encoding: ascii-8bit

require_relative 'spec_helper.rb'

# https://github.com/aalness/contracthashtool-ruby
# ruby port of https://github.com/Blockstream/contracthashtool

describe 'Bitcoin::ContractHash' do
  it 'should generate and claim' do
    Bitcoin::network = :testnet3

    # Example parameters from the original tool's usage().

    redeem_script_template = '5121038695b28f1649c711aedb1fec8df54874334cfb7ddf31ba3132a94d00bdc9715251ae'
    payee_address = 'mqWkEAFeQdrQvyaWNRn5vijPJeiQAjtxL2'
    nonce_hex = '3a11be476485a6273fad4a0e09117d42'
    private_key_wif = 'cMcpaCT6pHkyS4347i4rSmecaQtLiu1eH28NWmBiePn8bi6N4kzh'

    # Someone wanting to send funds to the sidechain would call this
    # to calculate a P2SH address to send to. They would then send the
    # MDFs (mutually distrusting functionaries) the target address
    # and nonce so they are able to locate the subsequent transaction.
    # The caller would then send the desired amount of coin to the P2SH
    # address to initiate the peg protocol.

    nonce, redeem_script, p2sh_address = Bitcoin::ContractHash.generate(redeem_script_template, payee_address, nonce_hex)

    nonce.should == "3a11be476485a6273fad4a0e09117d42"
    p2sh_address.should == "2MvGPFfDXbJZyH79u187VNZbuCgyRBhcdsw"
    redeem_script.should == "512102944aba05d40d8df1724f8ab2f5f3a58d052d26aedc93e175534cb782becc8ff751ae"

    # Each MDF would call this to derive a private key to redeem the
    # locked transaction.

    key = Bitcoin::ContractHash.claim(private_key_wif, payee_address, nonce)
    key.to_base58.should == "cSBD8yM62R82RfbugiGK8Lui9gdMB81NtZBckxe5YxRsDSKySwHK"

    # Verify homomorphic derivation was successful.

    signature = key.sign_message(message="derp")
    script = Bitcoin::Script.new([redeem_script].pack("H*"))
    pubkey = Bitcoin::Key.new(nil, script.get_multisig_pubkeys.first.unpack("H*").first)
    pubkey.verify_message(signature, message).should == true
  end
end
