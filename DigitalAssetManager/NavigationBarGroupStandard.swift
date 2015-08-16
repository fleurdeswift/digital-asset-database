//
//  NavigationBarGroupStandard.swift
//  DigitalAssetDatabase
//
//  Copyright © 2015 Fleur de Swift. All rights reserved.
//

import Foundation

public class NavigationBarGroupStandard : NavigationBarItemRoot {
    public init() {
        super.init(childs: [
            NavigationBarItemHistory(), NavigationBarItemDropBox(),
            NavigationBarItemHistory(), NavigationBarItemDropBox(),
            NavigationBarItemHistory(), NavigationBarItemDropBox(),
            NavigationBarItemHistory(), NavigationBarItemDropBox(),
            NavigationBarItemHistory(), NavigationBarItemDropBox(),
            NavigationBarItemHistory(), NavigationBarItemDropBox(),
            NavigationBarItemHistory(), NavigationBarItemDropBox(),
            NavigationBarItemHistory(), NavigationBarItemDropBox(),
            NavigationBarItemHistory(), NavigationBarItemDropBox(),
            NavigationBarItemHistory(), NavigationBarItemDropBox(),
        ]);
    }

    public required init?(coder decoder: NSCoder) {
        super.init(coder: decoder);
    }

    public override var description : String {
        return "Standard";
    }
}
